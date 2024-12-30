require 'test_helper'

class SqlConditionValidatorTest < ActiveSupport::TestCase
  def setup
    @validator = SqlConditionValidator.new
  end

  test "accepts valid WHERE clause with user_id and parenthesized condition" do
    valid_queries = [
      "SELECT * FROM users WHERE user_id = 1 AND (foo = bar)",
      "SELECT * FROM users WHERE user_id = 42 AND (status = 'active')",
      "SELECT * FROM users WHERE user_id = 999 AND (created_at > '2024-01-01')",
      "SELECT * FROM users WHERE user_id = 1 AND (points >= 100)",
      "SELECT * FROM users WHERE user_id = 1 AND (foo = bar OR baz = qux)",
    ]

    valid_queries.each do |query|
      assert @validator.validate_where_clause(query),
             "Expected to accept valid query: #{query}"
    end
  end

  test "rejects WHERE clause without parentheses around second condition" do
    invalid_queries = [
      "SELECT * FROM users WHERE user_id = 1 AND foo = bar",
      "SELECT * FROM users WHERE user_id = 1 AND status = 'active'"
    ]

    invalid_queries.each do |query|
      refute @validator.validate_where_clause(query),
             "Expected to reject query without parentheses: #{query}"
    end
  end

  test "rejects WHERE clause with invalid left side condition" do
    invalid_queries = [
      "SELECT * FROM users WHERE name = 'john' AND (foo = bar)",
      "SELECT * FROM users WHERE email = 'test@test.com' AND (foo = bar)",
      "SELECT * FROM users WHERE user_id != 1 AND (foo = bar)",
      "SELECT * FROM users WHERE user_id > 1 AND (foo = bar)",
      "SELECT * FROM users WHERE user_id AND (foo = bar)"
    ]

    invalid_queries.each do |query|
      refute @validator.validate_where_clause(query),
             "Expected to reject query with invalid left side: #{query}"
    end
  end

  test "rejects WHERE clause with OR conditions" do
    invalid_queries = [
      "SELECT * FROM users WHERE user_id = 1 OR (foo = bar)",
      "SELECT * FROM users WHERE user_id = 1 AND (foo = bar) OR (user_id = 2)",
    ]

    invalid_queries.each do |query|
      refute @validator.validate_where_clause(query),
             "Expected to reject query with OR conditions: #{query}"
    end
  end

  test "rejects WHERE clause with multiple AND conditions" do
    invalid_queries = [
      "SELECT * FROM users WHERE user_id = 1 AND (foo = bar) AND (baz = qux)",
      "SELECT * FROM users WHERE user_id = 1 AND foo = bar AND baz = qux"
    ]

    invalid_queries.each do |query|
      refute @validator.validate_where_clause(query),
             "Expected to reject query with multiple AND conditions: #{query}"
    end
  end

  test "rejects WHERE clause with non-numeric user_id" do
    invalid_queries = [
      "SELECT * FROM users WHERE user_id = '1' AND (foo = bar)",
      "SELECT * FROM users WHERE user_id = NULL AND (foo = bar)",
      "SELECT * FROM users WHERE user_id = true AND (foo = bar)"
    ]

    invalid_queries.each do |query|
      refute @validator.validate_where_clause(query),
             "Expected to reject query with non-numeric user_id: #{query}"
    end
  end

  test "handles edge cases and malformed queries" do
    invalid_queries = [
      "",
      "SELECT * FROM users",
      "SELECT * FROM users WHERE",
      "SELECT * FROM users WHERE AND",
      "SELECT * FROM users WHERE user_id = 1 AND",
      "SELECT * FROM users WHERE user_id = 1 AND ()",
      "SELECT * FROM users WHERE (foo = bar) AND user_id = 1"
    ]

    invalid_queries.each do |query|
      assert_nothing_raised do
        refute @validator.validate_where_clause(query),
               "Expected to reject malformed query: #{query}"
      end
    end
  end
end