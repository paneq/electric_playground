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
class SqlConditionValidator
  def validate_where_clause(sql)
    tree = PgQuery.parse(sql).tree
    where = tree.stmts[0].stmt.select_stmt.where_clause

    # Check if it's an AND expression
    return false unless where.bool_expr.boolop == :AND_EXPR
    return false unless where.bool_expr.args.length == 2

    left_condition = where.bool_expr.args[0].a_expr

    # Validate left side is user_id = <number>
    return false unless left_condition.kind == :AEXPR_OP
    return false unless left_condition.name[0].string.sval == "="
    return false unless left_condition.lexpr.column_ref.fields[0].string.sval == "user_id"
    return false unless left_condition.rexpr.a_const&.ival

    # Check if original SQL has parentheses around second condition
    # We can check this by looking at the raw SQL since the AST doesn't preserve parentheses
    second_condition_start = where.bool_expr.args[1].a_expr.location
    second_condition = sql[second_condition_start..-1]
    return false unless second_condition.start_with?("(") && second_condition.end_with?(")")

    true
  end
end
