#!/bin/bash
DATABASE_NAME="number_guess"
PSQL="psql --username=freecodecamp --dbname=$DATABASE_NAME -t --no-align -c"
#para saber las veces que se intenta
NUMBER_OF_GUESSES=1

GENERATE_NUMBER(){
  echo  "Guess the secret number between 1 and 1000:"
  SECRET_NUMBER=$(( $RANDOM % 1000 +1 ))
  NUMBER_INSERT_RESULT=$($PSQL "UPDATE users SET secret_number=$SECRET_NUMBER WHERE user_id=$USER_ID")
}

READ_NUMBER(){
  read USER_NUMBER
  GUESS_NUMBER
}

GUESS_NUMBER(){
  if [[ ! $USER_NUMBER =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    READ_NUMBER
  else 
    if [[ $USER_NUMBER -lt $SECRET_NUMBER ]]
    then
      echo "It's higher than that, guess again:"
      NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))
      READ_NUMBER
    elif [[ $USER_NUMBER -gt $SECRET_NUMBER ]]
    then
      echo "It's lower than that, guess again:"
      NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))
      READ_NUMBER
    elif [[ $USER_NUMBER -eq $SECRET_NUMBER  ]]
    then
      #CHECAR MEJOR JUEGO
      BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE user_id=$USER_ID")
      if [[ $BEST_GAME -gt $NUMBER_OF_GUESSES || $BEST_GAME -eq 0 ]]
      then
        BEST_INSERT_RESULT=$($PSQL "UPDATE users SET best_game=$NUMBER_OF_GUESSES WHERE user_id=$USER_ID")
      fi
      GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_id=$USER_ID")
      GAMES_PLAYED=$((GAMES_PLAYED + 1))
      GAMES_INSERT_RESULT=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED WHERE user_id=$USER_ID")
      SECRET_NUMBER=$($PSQL "SELECT secret_number FROM users WHERE user_id=$USER_ID")
      echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    fi
  fi
}


echo "Enter your username:"
read USER_NAME

USER_ID=$($PSQL "SELECT username FROM users WHERE username='$USER_NAME'")
  
#new users
if [[ -z $USER_ID ]]
then
  USER_NAME_INSERT_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USER_NAME')")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USER_NAME'")
  echo "Welcome, $USER_NAME! It looks like this is your first time here."
  GENERATE_NUMBER
else
  #user in database
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USER_NAME'")
  USERNAME=$($PSQL "SELECT username FROM users WHERE user_id=$USER_ID")
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_id=$USER_ID")
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE user_id=$USER_ID")
  echo  "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  GENERATE_NUMBER
fi

READ_NUMBER