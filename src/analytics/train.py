# %%

import pandas as pd

pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)

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
# EXPLORE BIVARIADA

# corrigir formatos

cat_features = ['descLifeCycleAtual', 'descLifeCycleD28']

num_features = list(set(features) - set(cat_features))
# num_features

df_train = X_train.copy()
df_train[target] = y_train.copy()

# converter para numericas
df_train[num_features] = df_train[num_features].astype(float)

# analise bivariada
bivariada = df_train.groupby(target)[num_features].median().T

# diferença de intensidade de cada feature
# se = 1 não faz diferença para o modelo
bivariada['ratio'] = (bivariada[1] + 0.001) / (bivariada[0] + 0.001)
bivariada.sort_values(by='ratio', ascending=False)

# remover features irrelevantes
to_remove = bivariada[bivariada['ratio']==1].index.tolist()
to_remove

for i in to_remove:
    features.remove(i)
    num_features.remove(i)

# %%
# contagem das features
len(num_features)

# %%

# refazendo analise bivariada
bivariada = df_train.groupby(target)[num_features].median().T
bivariada['ratio'] = (bivariada[1] + 0.001) / (bivariada[0] + 0.001)
bivariada.sort_values(by='ratio', ascending=False)

# %%
# bivarida categoriga
# quem tem mais propenção de se manter fiel?
# fazer gráfico
bivariada_cat = df_train.groupby('descLifeCycleAtual')[target].mean()
bivariada_cat

# %%
# comprovando que zumbi precisavam sair da análise
# fazer gráfico
bivariada_D28_cat = df_train.groupby('descLifeCycleD28')[target].mean()
bivariada_D28_cat

