# frozen_string_literal: true

class SqlConditionValidator
  def initialize(user_id)
    @user_id = user_id
  end

  # Validates a WHERE clause to ensure it only contains
  # conditions that are of format
  #   user_id = <number> AND (...)
  def validate_where_clause(where_clause)
    # In PostgreSQL (and SQL in general), the AND operator has higher precedence
    # than the OR operator.
    #
    # This means that in an expression containing both AND and OR, the AND part
    # will be evaluated first unless parentheses are used to change the
    # order of evaluation.
    #
    # For example, in the following expression:
    #
    # SELECT * FROM table WHERE condition1 AND condition2 OR condition3;
    # This will be interpreted as:
    # SELECT * FROM table WHERE (condition1 AND condition2) OR condition3;
    sql = "SELECT * FROM f WHERE #{where_clause}"
    begin
      parsed = PgQuery.parse(sql)
      tree = parsed.tree
      stmt = tree.stmts[0]&.stmt
      return false unless stmt

      where = stmt.select_stmt&.where_clause
      return false unless where&.bool_expr

      # Check if it's an AND expression
      return false unless where.bool_expr.boolop == :AND_EXPR
      return false unless where.bool_expr.args.length == 2

      left_condition = where.bool_expr.args[0]&.a_expr
      return false unless left_condition

      # Validate left side is user_id = <current user id>
      return false unless left_condition.kind == :AEXPR_OP
      return false unless left_condition.name[0]&.string&.sval == "="

      left_field = left_condition.lexpr&.column_ref&.fields&.first
      return false unless left_field&.string&.sval == "user_id"

      return false unless left_condition.rexpr&.a_const&.ival&.ival == @user_id

      right_expr = where.bool_expr.args[1]
      return false unless right_expr
      return true
    rescue PgQuery::ParseError
      false
    end
  end
end
