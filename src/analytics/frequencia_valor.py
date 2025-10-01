# %%

import pandas as pd
import numpy as np
import sqlalchemy 
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn import cluster

# %%
# abre conexão com o database transacional
engine = sqlalchemy.create_engine("sqlite:///../../data/loyalty-system/database.db")

# %%
def import_query(path):
    with open(path) as open_file:
        return open_file.read()
    
query = import_query("frequencia_valor.sql")

# %%
df = pd.read_sql(query, engine)
df.head()

# %%
plt.plot(df["qtdeFrequencia"], df["qtdePontosPos"], 'o')
plt.grid(True)
plt.title("Frequencia x Pontos Gastos")
plt.xlabel("Frequencia")
plt.ylabel("Valor")
plt.show()

# %%
kmean = cluster.KMeans(n_clusters=5, random_state=42, max_iter=1000)
kmean.fit(df[["qtdeFrequencia","qtdePontosPos"]])

df["cluster"] = kmean.labels_

df.groupby(by="cluster")["IdCliente"].count()

# %%
sns.scatterplot(data=df,
                x="qtdeFrequencia",
                y="qtdePontosPos", hue="cluster",
                palette="deep")
plt.grid()
plt.show()

# %%
# remover outlier e normalizar