# %%
# aplicar modelo direto do mlflow a dados mais recentes

import pandas as pd
import sqlalchemy
import mlflow

# abrindo conexão com o banco de dados
con = sqlalchemy.create_engine("sqlite:///../../data/analytics/database.db")
# abrindo conexão com o Mlflow
mlflow.set_tracking_uri("http://localhost:5000")

# %%
# pega a versão mais recente
versions = mlflow.search_model_versions(filter_string="name='model_fiel'")
last_version = max([int(i.version) for i in versions])
model = mlflow.sklearn.load_model(f"models:///model_fiel/{last_version}")

# %%
# faz a predição
data = pd.read_sql("SELECT * FROM fs_all", con)
predict = model.predict_proba(data[model.feature_names_in_])[:,1]
# probabilidade de fiel
data["predictFiel"] = predict

# tabela com informacoes relevantes
data = data[['dtRef', 'IdCliente', 'predictFiel']]

# %%

# salvando a predição em batch para uma tabela SQL no banco
data.to_sql("score_fiel", con, index=False, if_exists='replace')