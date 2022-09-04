FROM debian:11.3@sha256:3f1d6c17773a45c97bd8f158d665c9709d7b29ed7917ac934086ad96f92e4510 AS builder

RUN apt-get update && \
    apt-get install --no-install-recommends --yes \
    ca-certificates=20210119 \
    bzip2=1.0.8-4 \
    curl=7.74.0-1.3+deb11u2

ENV INSTALLER bin/micromamba
# hadolint ignore=DL4006
RUN curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj ${INSTALLER}

ARG PYTHON_VERSION
ARG PIP_VERSION
ARG RUNTIME_DIR=/opt/runtime

RUN ${INSTALLER} create -qp ${RUNTIME_DIR} && \
    ${INSTALLER} install -qp ${RUNTIME_DIR} \
    python=${PYTHON_VERSION} \
    pip=${PIP_VERSION} \
    libstdcxx-ng=12.1.0 \
    -c conda-forge -c anaconda -y

COPY ./requirements.txt /python-requirements/
COPY ./vendor-requirements.txt /python-requirements/
RUN ${RUNTIME_DIR}/bin/python3 -m pip install -q \
    --disable-pip-version-check \
    --no-warn-script-location \
    --root-user-action=ignore \
    --progress-bar off \
    --no-cache \
    --requirement /python-requirements/requirements.txt \
    --requirement /python-requirements/vendor-requirements.txt


FROM gcr.io/distroless/base-debian11@sha256:e672eb713e56feb13e349773973b81b1b9284f70b15cf18d1a09ad31a03abe59

ARG RUNTIME_DIR=/opt/runtime

COPY --from=builder ${RUNTIME_DIR} /opt/python

USER nonroot

ENTRYPOINT ["/opt/python/bin/python3", "-m", "layer.executables.runtime"]
