#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

secret_number=$((RANDOM % 1000 + 1))

echo "Enter your username:"
read -r username
username_sql=${username//\'/\'\'}

user_data=$($PSQL "SELECT games_played, COALESCE(best_game::text, '') FROM users WHERE username = '$username_sql'")

if [[ -z $user_data ]]; then
  echo "Welcome, $username! It looks like this is your first time here."
  $PSQL "INSERT INTO users (username) VALUES ('$username_sql')" > /dev/null
else
  IFS='|' read -r games_played best_game <<< "$user_data"
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

echo "Guess the secret number between 1 and 1000:"
guesses=0

while true; do
  if ! IFS= read -r guess; then
    exit 1
  fi
  guesses=$((guesses + 1))

  if [[ ! $guess =~ ^-?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  if [[ $guess == -* ]]; then
    guess_value=$((-10#${guess#-}))
  else
    guess_value=$((10#$guess))
  fi

  if (( guess_value == secret_number )); then
    break
  elif (( guess_value > secret_number )); then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

echo "You guessed it in $guesses tries. The secret number was $secret_number. Nice job!"
$PSQL "UPDATE users SET games_played = games_played + 1, best_game = CASE WHEN best_game IS NULL OR $guesses < best_game THEN $guesses ELSE best_game END WHERE username = '$username_sql'" > /dev/null