import requests
import random
import time

# Create dummy boards
POST_BOARD_URL = "http://localhost:8080/api/boards"

question_set = {f"Question {i}" for i in range(1, 26)}
board_name = "Sample Board"
board_author = "Kyle Rosenau"

payload = {
    "questions": list(question_set),
    "name": board_name,
    "author": board_author
}

# print(f"Creating board: {payload}")

response = requests.post(POST_BOARD_URL, json=payload)

if response.status_code == 200:
    print("  ✔ Board created:", response.json())
else:
    print("  ✘ Failed to create board:", response.status_code, response.text)



# API_URL = "http://localhost:8080/api/games"

# # Example boards you may have in your DB
# BOARD_IDS = [1, 2, 3, 4, 5]

# HOST_NAMES = [
#     "Alice", "Bob", "Charlie", "Diana", "Ethan", "Fiona",
#     "George", "Hannah", "Isaac", "Julia"
# ]

# def create_dummy_game():
#     host_name = random.choice(HOST_NAMES)
#     board_id = random.choice(BOARD_IDS)
#     is_public = random.choice([True, False])

#     # Public games do not need passwords; private games get one
#     password = "" if is_public else f"pass{random.randint(100, 999)}"

#     payload = {
#         "hostName": host_name,
#         "boardId": board_id,
#         "isPublic": is_public,
#         "password": password
#     }

#     print(f"Creating game: {payload}")

#     response = requests.post(API_URL, json=payload)

#     if response.status_code == 200:
#         print("  ✔ Success:", response.json())
#     else:
#         print("  ✘ Failed:", response.status_code, response.text)


# def create_multiple_games(num_games=10):
#     for _ in range(num_games):
#         create_dummy_game()
#         time.sleep(0.2)  # Slight delay to make logs readable

# if __name__ == "__main__":
#     create_multiple_games(5)