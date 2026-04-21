# syntax=docker/dockerfile:1.6

# Base de Ubuntu pinneada por digest para builds reproducibles.
ARG UBUNTU_VERSION=22.04
ARG UBUNTU_DIGEST=3ba65aa20f86a0fad9df2b2c259c613df006b2e6d0bfcc8a146afb8c525a9751

FROM ubuntu:${UBUNTU_VERSION}@sha256:${UBUNTU_DIGEST}

# Argumentos de build del contenedor.
ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
ARG LOCALE=en_US.UTF-8

# Versiones pinneadas de la toolchain Haskell.
ARG GHC_VERSION=9.14.1
ARG CABAL_VERSION=3.14.2.0
ARG ALEX_VERSION=3.5.4.0
ARG HAPPY_VERSION=2.2
ARG GHCUP_METADATA_REF=master

# Dependencias del sistema para compilar GHC y herramientas auxiliares.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        build-essential \
        curl \
        wget \
        ca-certificates \
        xz-utils \
        gzip \
        bzip2 \
        unzip \
        tar \
        pkg-config \
        python3 \
        perl \
        time \
        jq \
        diffutils \
        autoconf \
        automake \
        libtool \
        libgmp-dev \
        zlib1g-dev \
        libncurses-dev \
        libffi-dev \
        locales \
        sudo \
        gnupg \
        dirmngr \
    && rm -rf /var/lib/apt/lists/*

# Genera locale UTF-8 dentro de la imagen.
RUN locale-gen "${LOCALE}" \
    && update-locale LANG="${LOCALE}" LC_ALL="${LOCALE}"

# Variables regionales y zona horaria por defecto.
ENV LANG=${LOCALE}
ENV LC_ALL=${LOCALE}
ENV TZ=Etc/UTC

# Crea un usuario no-root para desarrollo en Dev Containers.
RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" -m "${USERNAME}" -s /bin/bash \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}"

# Todo corre como usuario no-root.
USER ${USERNAME}
ENV HOME=/home/${USERNAME}

# PATH para binaries instalados por cabal y ghcup.
ENV PATH=${HOME}/.local/bin:${HOME}/.ghcup/bin:${PATH}
ENV GHCUP_SKIP_UPDATE_CHECK=1

# Directorio para binarios de usuario instalados con cabal.
RUN mkdir -p "${HOME}/.local/bin"

# Instalacion de GHCup: administrador de toolchain Haskell.
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org -o /tmp/ghcup.sh \
    && chmod +x /tmp/ghcup.sh \
    && BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
       BOOTSTRAP_HASKELL_MINIMAL=1 \
       BOOTSTRAP_HASKELL_INSTALL_NO_STACK=1 \
       BOOTSTRAP_HASKELL_INSTALL_HLS=0 \
       BOOTSTRAP_HASKELL_ADJUST_BASHRC=0 \
       /bin/bash /tmp/ghcup.sh \
    && rm /tmp/ghcup.sh

# Configuracion de metadata local para evitar consultas remotas en cada uso de ghcup.
RUN mkdir -p "${HOME}/git" "${HOME}/.ghcup" \
    && git clone --depth 1 --branch "${GHCUP_METADATA_REF}" https://github.com/haskell/ghcup-metadata.git "${HOME}/git/ghcup-metadata" \
    && printf '%s\n' \
         'url-source:' \
         '  - file:///home/vscode/git/ghcup-metadata/ghcup-0.0.9.yaml' \
       > "${HOME}/.ghcup/config.yaml"

# Instalación con versiones fijas:
# - GHC: compilador de Haskell
# - cabal: gestor de paquetes/build de Haskell
# - alex: generador de analizadores lexicos
# - happy: generador de analizadores sintacticos
RUN ghcup install ghc "${GHC_VERSION}" \
    && ghcup set ghc "${GHC_VERSION}" \
    && ghcup install cabal "${CABAL_VERSION}" \
    && ghcup set cabal "${CABAL_VERSION}" \
    && cabal update \
    && cabal install "alex-${ALEX_VERSION}" "happy-${HAPPY_VERSION}" \
         --installdir="${HOME}/.local/bin" \
         --install-method=copy \
         --overwrite-policy=always \
    && rm -rf "${HOME}/.ghcup/tmp" "${HOME}/.cabal/packages" "${HOME}/.cabal/logs"

# Verificación de las instalaciones con versiones fijas.
RUN ghc --numeric-version \
    && cabal --numeric-version \
    && alex --version \
    && happy --version

# Ruta de trabajo por defecto en el devcontainer.
WORKDIR /workspaces/tt-repo
