# gestão da projeto Makefile
# script para definir ordem dos comandos

# Define o ambiente Conda
CONDA_ENV=loyalty-predict

# Define o diretório do amabiente virtual
VENV_DIR=.venv

# Define os diretórios
ENGENEERING_DIR=src/engineering
ANALYSIS_DIR=src/analysis

CONDA_PYTHON := $(shell which python)


# Configura o ambiente virtual
.PHONY: setup
setup:
	@echo "Criando ambiente virtual..."
	python -m venv $(VENV_DIR)
	@echo "Ativando ambiente virtual e instalando dependências..."
	$(VENV_DIR)\Scripts\activate && pip install -r requirements.txt

# Executa os scripts
.PHONY: run
run:
	@echo "Ativando ambiente virtual..."
	$(VENV_DIR)\Scripts\activate && \
	cd src/engineering && \
	python get_data.py && \
	cd ../analytics && \
	python pipeline_analytics.py

all: setup run