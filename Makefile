.PHONY: build-geyser-mc
build-geyser-mc:
	@docker build ./GeyserMC -t ghcr.io/asteurer/geysermc && \
		docker login ghcr.io && \
		docker push ghcr.io/asteurer/geysermc