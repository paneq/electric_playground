require 'test_helper'

class SqlConditionValidatorTest < ActiveSupport::TestCase
  def setup
    @validator = SqlConditionValidator.new(1)
  end

  test "accepts valid WHERE clause with root AND, and user_id check on the left side" do
    valid_queries = [
      "user_id = 1 AND (foo = bar)",
      "user_id = 1 AND (status = 'active')",
      "user_id = 1 AND (created_at > '2024-01-01')",
      "user_id = 1 AND (points >= 100)",
      "user_id = 1 AND (foo = bar OR baz = qux)",
      "user_id = 1 AND (foo = bar AND baz = qux)",
      "user_id = 1 AND foo = bar",
      "user_id = 1 AND status = 'active'"
    ]

    valid_queries.each do |query|
      assert @validator.validate_where_clause(query),
             "Expected to accept valid query: #{query}"
    end
  end

  test "rejects WHERE clause with invalid left side condition" do
    invalid_queries = [
      "user_id = 2 AND (foo = bar)",
      "name = 'john' AND (foo = bar)",
      "email = 'test@test.com' AND (foo = bar)",
      "user_id != 1 AND (foo = bar)",
      "user_id > 1 AND (foo = bar)",
      "user_id AND (foo = bar)",
      "user_id IS NULL AND (foo = bar)",
      "user_id IS NOT NULL AND (foo = bar)",
      "user_id IN (1,2) AND (foo = bar)",
    ]

    invalid_queries.each do |query|
      refute @validator.validate_where_clause(query),
             "Expected to reject query with invalid left side: #{query}"
    end
  end

  test "rejects WHERE clause with root OR conditions" do
    invalid_queries = [
      "user_id = 1 OR (foo = bar)",
      "user_id = 1 AND (foo = bar) OR (user_id = 2)",
      "user_id = 1 AND foo = bar OR user_id = 2",
      "(user_id = 1 AND foo = bar) OR user_id = 2",
    ]

    invalid_queries.each do |query|
      refute @validator.validate_where_clause(query),
             "Expected to reject query with OR conditions: #{query}"
    end
  end

  test "rejects WHERE clause with multiple AND conditions" do
    invalid_queries = [
      "user_id = 1 AND (foo = bar) AND (baz = qux)",
      "user_id = 1 AND foo = bar AND baz = qux"
    ]

    invalid_queries.each do |query|
      refute @validator.validate_where_clause(query),
             "Expected to reject query with multiple AND conditions: #{query}"
    end
  end

  test "rejects WHERE clause with non-numeric user_id" do
    invalid_queries = [
      "user_id = '1' AND (foo = bar)",
      "user_id = NULL AND (foo = bar)",
      "user_id = true AND (foo = bar)"
    ]

    invalid_queries.each do |query|
      refute @validator.validate_where_clause(query),
             "Expected to reject query with non-numeric user_id: #{query}"
    end
  end

  test "handles edge cases and malformed queries" do
    invalid_queries = [
      "",
      "AND",
      "user_id = 1 AND",
      "user_id = 1 AND ()",
      "(foo = bar) AND user_id = 1"
    ]

    invalid_queries.each do |query|
      assert_nothing_raised do
        refute @validator.validate_where_clause(query),
               "Expected to reject malformed query: #{query}"
      end
    end
  end
end
