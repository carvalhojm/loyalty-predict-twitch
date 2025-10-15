# %%
import pandas as pd

import sqlalchemy 

from feature_engine import selection
from feature_engine import imputation
from feature_engine import encoding

# pd.set_option('display.max_columns', None)
# pd.set_option('display.max_rows', None)

con = sqlalchemy.create_engine("sqlite:///../../data/analytics/database.db")

# %%
# SAMPLE - IMPORT DOS DADOS

df = pd.read_sql("select * from abt_fiel", con)
df.head()

# %%
# SAMPLE - OOT 

df_oot = df[df['dtRef']==df['dtRef'].max()].reset_index(drop=True)
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

# to_remove = bivariada[bivariada['ratio']==1].index.tolist()
# to_remove

# for i in to_remove:
#     features.remove(i)
#     num_features.remove(i)

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

# %%
## MODIFY - DROP

X_train[num_features] = X_train[num_features].astype(float)

# remover features irrelevantes
to_remove = bivariada[bivariada['ratio']==1].index.tolist()
to_remove

# %%
# criando um objeto com as alterações para remoção de features
drop_features = selection.DropFeatures(to_remove)
drop_features

# %%
# aplicar alterações
X_train_transform = drop_features.fit_transform(X_train)

# %%
## MODIFY - MISSING
# conferindo features com valores null
s_na = X_train_transform.isna().mean()
s_na[s_na>0]

# %%
# imputação para 0
fill_0 = ['github2025', 'python2025']
imput_0 = imputation.ArbitraryNumberImputer(arbitrary_number=0, 
                                            variables=fill_0)

# imputação para categorico
imput_new = imputation.CategoricalImputer(
    fill_value='Nao-Usuario',
    variables=['descLifeCycleD28']
)

# imputação para maior valor
imput_1000 = imputation.ArbitraryNumberImputer(
    arbitrary_number=1000,
    variables=['avgIntervaloDiasVida',
               'avgIntervaloDias28',
               'qtdeDiasUltiAtividade']
)

# aplicar no treino as imputações
X_train_transform = imput_0.fit_transform(X_train_transform)
X_train_transform = imput_new.fit_transform(X_train_transform)
X_train_transform = imput_1000.fit_transform(X_train_transform)

# %%
# checagem features com valores null
s_na = X_train_transform.isna().mean()
s_na[s_na>0]

# %%
## MODIFY - ONEHOT

# variaveis categoricas modificadas para ML
X_train_transform[cat_features].head()

# se tivessem muitas categorias categoricas -> 
# usar MeanEncoder() do feature-engine

onehot = encoding.OneHotEncoder(variables=cat_features)

X_train_transform = onehot.fit_transform(X_train_transform)

# %%
X_train_transform.head()

# %%
## MODEL

from sklearn import tree
from sklearn import ensemble

# model = tree.DecisionTreeClassifier(random_state=42, min_samples_leaf=50)
# model = ensemble.RandomForestClassifier(random_state=42,
#                                         n_estimators=150,
#                                         n_jobs=-1,
#                                         min_samples_leaf=60)
model = ensemble.AdaBoostClassifier(random_state=42,
                                        n_estimators=150,
                                        learning_rate=0.1,)
model.fit(X_train_transform, y_train)

# %%
## ASSESS

from sklearn import metrics

y_pred_train = model.predict(X_train_transform)
y_proba_train = model.predict_proba(X_train_transform)

acc_train = metrics.accuracy_score(y_train, y_pred_train)
auc_train = metrics.roc_auc_score(y_train, y_proba_train[:,1])

print("Acurácia Treino:", acc_train)
print("AUC Treino:", acc_train)

# %%

X_test_transform = drop_features.transform(X_test)
X_test_transform = imput_0.transform(X_test_transform)
X_test_transform = imput_new.transform(X_test_transform)
X_test_transform = imput_1000.transform(X_test_transform)
X_test_transform = onehot.transform(X_test_transform)

y_pred_test = model.predict(X_test_transform)
y_proba_test = model.predict_proba(X_test_transform)

acc_test = metrics.accuracy_score(y_test, y_pred_test)
auc_test = metrics.roc_auc_score(y_test, y_proba_test[:,1])

print("Acurácia Teste:", acc_test)
print("AUC Teste:", acc_test)

# %%
# testando no Out of Time

X_oot = df_oot[features]
y_oot = df_oot[target]

X_oot_transform = drop_features.transform(X_oot)
X_oot_transform = imput_0.transform(X_oot_transform)
X_oot_transform = imput_new.transform(X_oot_transform)
X_oot_transform = imput_1000.transform(X_oot_transform)
X_oot_transform = onehot.transform(X_oot_transform)

y_pred_oot = model.predict(X_oot_transform)
y_proba_oot = model.predict_proba(X_oot_transform)

acc_oot = metrics.accuracy_score(y_oot, y_pred_oot)
auc_oot = metrics.roc_auc_score(y_oot, y_proba_oot[:,1])

print("Acurácia OOT:", acc_oot)
print("AUC OOT:", acc_oot)

# %%
# descobrir feaatures com mais importacia para o modelo
features_names = X_train_transform.columns.tolist()

feature_importance = pd.Series(model.feature_importances_,
                               index=features_names)

feature_importance.sort_values(ascending=False)
