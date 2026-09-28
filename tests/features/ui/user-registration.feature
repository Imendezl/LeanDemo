Feature: User registration
  As a new platform user
  I want to create an account with my personal data
  So that I can access the application

  Background:
    Given the registration application is available

  Scenario: Successful registration with dynamic data
    Given I generate random test data for a new user
    When I fill the registration form with the generated data
    And I submit the form
    Then I see the successful registration message
    And the user is stored in the system

  Scenario: The form cannot be submitted with empty required fields
    When I submit an empty form
    Then I see the validation errors for all required fields
    And I do not see the successful registration message

  Scenario: Rejects an email address with an invalid format
    Given I generate random test data for a new user
    When I fill the registration form with the generated data
    And I type "correo-no-valido" into the "email" field
    And I submit the form
    Then I see the validation error "Introduce un correo electrónico válido" in the "email" field
    And I do not see the successful registration message

  Scenario: Rejects a weak password
    Given I generate random test data for a new user
    When I fill the registration form with the generated data
    And I type "abc123" into the "password" field
    And I submit the form
    Then I see the validation error "La contraseña debe tener al menos 8 caracteres e incluir letras y números" in the "password" field
    And I do not see the successful registration message

  Scenario: Requires accepting the terms and conditions
    Given I generate random test data for a new user
    When I fill the registration form with the generated data
    And I uncheck the terms and conditions checkbox
    And I submit the form
    Then I see the validation error "Debes aceptar los términos y condiciones" in the "terms" field
    And I do not see the successful registration message

  Scenario: Rejects an email address that is already registered
    Given a user with dynamic data is already registered
    When I fill the registration form with the existing user's email
    And I submit the form
    Then I see the validation error "El correo electrónico ya está registrado" in the "email" field
    And I do not see the successful registration message

  Scenario Outline: Successful registration from different countries
    Given I generate random test data for a new user
    When I fill the registration form with the generated data and country "<country>"
    And I submit the form
    Then I see the successful registration message

    Examples:
      | country   |
      | España    |
      | México    |
      | Argentina |
