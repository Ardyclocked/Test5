#!/bin/bash

DB_NAME="number_guess"
DB_CMD="psql --username=freecodecamp --dbname=$DB_NAME -t --no-align -c"
ATTEMPTS=1

generate_secret_number() {
  echo "Guess the secret number between 1 and 1000:"
  SECRET_NUM=$(( RANDOM % 1000 + 1 ))
  UPDATE_SECRET=$($DB_CMD "UPDATE users SET secret_number=$SECRET_NUM WHERE user_id=$USER_ID")
}

read_and_guess() {
  read GUESS
  process_guess
}

process_guess() {
  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    read_and_guess
  else
    if [[ $GUESS -lt $SECRET_NUM ]]; then
      echo "It's higher than that, guess again:"
      ATTEMPTS=$((ATTEMPTS + 1))
      read_and_guess
    elif [[ $GUESS -gt $SECRET_NUM ]]; then
      echo "It's lower than that, guess again:"
      ATTEMPTS=$((ATTEMPTS + 1))
      read_and_guess
    else
      # Update best game record if needed
      BEST_ATTEMPT=$($DB_CMD "SELECT best_game FROM users WHERE user_id=$USER_ID")
      if [[ $BEST_ATTEMPT -gt $ATTEMPTS || $BEST_ATTEMPT -eq 0 ]]; then
        UPDATE_BEST=$($DB_CMD "UPDATE users SET best_game=$ATTEMPTS WHERE user_id=$USER_ID")
      fi
      
      # Update games played count
      GAMES_PLAYED=$($DB_CMD "SELECT games_played FROM users WHERE user_id=$USER_ID")
      UPDATED_GAMES_PLAYED=$((GAMES_PLAYED + 1))
      UPDATE_GAMES=$($DB_CMD "UPDATE users SET games_played=$UPDATED_GAMES_PLAYED WHERE user_id=$USER_ID")
      
      # Retrieve and display the secret number
      SECRET_NUM=$($DB_CMD "SELECT secret_number FROM users WHERE user_id=$USER_ID")
      echo "You guessed it in $ATTEMPTS tries. The secret number was $SECRET_NUM. Nice job!"
    fi
  fi
}

echo "Enter your username:"
read USERNAME

USER_ID=$($DB_CMD "SELECT user_id FROM users WHERE username='$USERNAME'")

if [[ -z $USER_ID ]]; then
  # New user
  ADD_USER=$($DB_CMD "INSERT INTO users(username) VALUES('$USERNAME')")
  USER_ID=$($DB_CMD "SELECT user_id FROM users WHERE username='$USERNAME'")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  generate_secret_number
else
  # Existing user
  USER_ID=$($DB_CMD "SELECT user_id FROM users WHERE username='$USERNAME'")
  USERNAME=$($DB_CMD "SELECT username FROM users WHERE user_id=$USER_ID")
  GAMES_PLAYED=$($DB_CMD "SELECT games_played FROM users WHERE user_id=$USER_ID")
  BEST_ATTEMPT=$($DB_CMD "SELECT best_game FROM users WHERE user_id=$USER_ID")
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_ATTEMPT guesses."
  generate_secret_number
fi

read_and_guess
