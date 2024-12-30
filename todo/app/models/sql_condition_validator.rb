# frozen_string_literal: true

class SqlConditionValidator
  def validate_where_clause(sql)
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

      # Validate left side is user_id = <number>
      return false unless left_condition.kind == :AEXPR_OP
      return false unless left_condition.name[0]&.string&.sval == "="

      left_field = left_condition.lexpr&.column_ref&.fields&.first
      return false unless left_field&.string&.sval == "user_id"

      return false unless left_condition.rexpr&.a_const&.ival

      right_expr = where.bool_expr.args[1]
      return false unless right_expr
      return true
    rescue PgQuery::ParseError
      false
    end
  end
end
