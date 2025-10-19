# Gestão da projeto Makefile
# Script para definir ordem dos comandos

# Define o ambiente Conda
CONDA_ENV=loyalty-predict

# Define o diretório do amabiente virtual
VENV_DIR=.venv

# Define os diretórios
ENGINEERING_DIR=src/engineering
ANALYTICS_DIR=src/analytics

CONDA_PYTHON := $(shell which python)

# Detecta o executável python dentro do virtualenv (prioriza python.exe no Windows, depois scripts/python, depois bin/python)
VENV_PY := $(shell if [ -x "$(VENV_DIR)/Scripts/python.exe" ]; then echo "$(VENV_DIR)/Scripts/python.exe"; elif [ -x "$(VENV_DIR)/Scripts/python" ]; then echo "$(VENV_DIR)/Scripts/python"; else echo "$(VENV_DIR)/bin/python"; fi)

# Configura o ambiente virtual
.PHONY: setup
setup:
	rm -rf $(VENV_DIR)
	@echo "Criando ambiente virtual..."
	python -m venv $(VENV_DIR)
	@echo "Instalando dependências no venv ($(VENV_PY))..."
	$(VENV_PY) -m pip install --upgrade pip
	$(VENV_PY) -m pip install pipreqs
	# pipreqs may not provide a __main__; use module path to invoke
	$(VENV_PY) -m pipreqs.pipreqs src/ --force --savepath requirements.txt
	$(VENV_PY) -m pip install -r requirements.txt

# Executa os scripts
.PHONY: run
run:
	@echo "Executando scripts com o Python do venv..."
	# Garante diretorios de dados necessarios (compativel com Git Bash)
	@mkdir -p data/loyalty-system
	# Executa get_data.py no diretório src/engineering (assim os caminhos relativos do script funcionam)
	cd $(ENGINEERING_DIR) && KAGGLE_CONFIG_DIR=$(CURDIR) $(abspath $(VENV_PY)) get_data.py && \
	cd ../analytics && KAGGLE_CONFIG_DIR=$(CURDIR) $(abspath $(VENV_PY)) pipeline_analytics.py

# Alvo padrão
.PHONY: all
all: setup run

.PHONY: check-env
check-env:
	@echo "Makefile debug: VENV_DIR=$(VENV_DIR)"
	@echo "Makefile debug: VENV_PY=$(VENV_PY)"
	@echo "Make version: $(shell make --version 2>/dev/null || echo make-not-found)"