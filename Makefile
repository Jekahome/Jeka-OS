.PHONY: all commit clean

all: commit

commit:
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo ">>> Обнаружены изменения, делаю коммит..."; \
		git add . && \
		DATE_STR="$$(date '+%Y-%m-%d %H:%M:%S')"; \
		git commit -m "$$DATE_STR" && \
		git push; \
	else \
		echo ">>> Нет изменений для коммита."; \
	fi

clean:
	git clean -fd