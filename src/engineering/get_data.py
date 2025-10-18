# %%
# import os
import dotenv

import shutil

# criar variaveis ambientes
dotenv.load_dotenv("../../.env")

# print(os.environ["KAGGLE_USERNAME"])
# print(os.environ["KAGGLE_KEY"])

from kaggle import api

# %%
# definire os datasets do Kaggle
datasets = [
    "teocalvo/teomewhy-loyalty-system",
    "teocalvo/teomewhy-education-platform",
]

# fazer o download de forma automatica
for d in datasets:
    dataset_name = d.split("teomewhy-")[-1]
    print(dataset_name)
    path = f"../../data/{dataset_name}/database.db"
    api.dataset_download_file(d, "database.db")
    shutil.move("database.db", path)