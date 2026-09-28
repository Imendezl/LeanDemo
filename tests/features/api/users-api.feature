Feature: Users API
  Backend contract tests, executed directly against the API
  for fast feedback without browser overhead

  Scenario: The service is healthy
    When I check the service health
    Then the response has status code 200
    And the reported status is "ok"

  Scenario: Create a user with dynamic data
    Given I generate random test data for a new user
    When I create the user through the API
    Then the response has status code 201
    And the created user matches the generated data

  Scenario: Rejects creating a user with a duplicate email
    Given a user with dynamic data is already registered
    When I create the existing user again through the API
    Then the response has status code 409
    And the response contains the error "El correo electrónico ya está registrado"

  Scenario Outline: Rejects registrations missing required fields
    Given I generate random test data for a new user
    When I create a user through the API without the "<field>" field
    Then the response has status code 400
    And the response contains the validation error for "<field>"

    Examples:
      | field       |
      | fullName    |
      | email       |
      | password    |
      | country     |
      | acceptTerms |

  Scenario: The users list includes the created ones
    Given I generate random test data for a new user
    And I create the user through the API
    When I fetch the users list
    Then the response has status code 200
    And the users list includes the generated user
