# frozen_string_literal: true

# # Valid cases
# validate_where_clause("SELECT * FROM users WHERE user_id = 1 AND (foo = bar)")  # => true
# validate_where_clause("SELECT * FROM users WHERE user_id = 42 AND (status = 'active')")  # => true
#
# # Invalid cases
# validate_where_clause("SELECT * FROM users WHERE user_id = 1 AND foo = bar")  # => false (no parentheses)
# validate_where_clause("SELECT * FROM users WHERE name = 'john' AND (foo = bar)")  # => false (left side not user_id)
# validate_where_clause("SELECT * FROM users WHERE user_id = 1 OR (foo = bar)")  # => false (OR instead of AND)
# validate_where_clause("SELECT * FROM users WHERE user_id = 1 AND (foo = bar) OR (user_id = 2)")  # => false (extra conditions)
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

      # Check if original SQL has parentheses around second condition
      right_expr = where.bool_expr.args[1]
      return false unless right_expr

      # Get the part of SQL that contains the right expression
      if right_expr.a_expr
        # For simple expressions
        position = right_expr.a_expr.location
        remainder = sql[position..-1]
      elsif right_expr.bool_expr
        # For boolean expressions (like OR conditions)
        position = right_expr.bool_expr.location
        remainder = sql[position..-1]
      else
        return false
      end

      # Find the first opening parenthesis after "AND"
      and_pos = sql.index(' AND ')
      return false unless and_pos

      right_side = sql[and_pos + 5..-1].strip
      return false unless right_side.start_with?('(') && right_side.end_with?(')')

      true
    rescue PgQuery::ParseError
      false
    end
  end
end
