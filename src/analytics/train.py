# %%

import pandas as pd

# pd.set_option('display.max_xolumns', None)

import sqlalchemy 

con = sqlalchemy.create_engine("sqlite:///../../data/analytics/database.db")

# %%
# SAMPLE - IMPORT DOS DADOS

df = pd.read_sql("abt_fiel", con)
df.head()

# %%
# SAMPLE - OOT 

df_oot = df[df['dtRef']==df['dtRef'].max()]
df_oot

# %%
# SAMPLE - Teste e treino

target = 'flFiel'
# converter em lista
features = df.columns.tolist()[3:]

# retirar o OOT
df_train_test = df[df['dtRef']<df['dtRef'].max()].reset_index(drop=True)

X = df_train_test[features] # pd.Series (vetor)
y = df_train_test[target]   # pd.DataFrame (matriz)

from sklearn import model_selection

X_train, X_test, y_train, y_test = model_selection.train_test_split(
    X, y, test_size=0.2, 
    random_state= 42, stratify= y
)

print(f"Base Treino: {y_train.shape[0]} Unid. | Tx. Targe {100*y_train.mean():.2f}%")
print(f"Base Test: {y_test.shape[0]} Unid. | Tx. Targe {100*y_test.mean():.2f}%")

# %%
# EXPLORE - MISSING

s_nas = X_train.isna().mean()
s_nas = s_nas[s_nas > 0]
s_nas

# %%
# avaliando bug
# df[df['descLifeCycleAtual'].isna()]

# %%

df_train = X_train.copy()
df_train[target] = y_train.copy()