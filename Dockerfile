FROM squidfunk/mkdocs-material:9.5.27

WORKDIR /tmp
RUN pip install mkdocs-add-number-plugin mkdocs-git-revision-date-localized-plugin mkdocs-open-in-new-tab mkdocs-print-site-plugin mdx_truly_sane_lists
RUN git config --global --add safe.directory /docs

WORKDIR /docs
EXPOSE 8000

ENTRYPOINT ["mkdocs"]
CMD ["serve", "--dev-addr=0.0.0.0:8000"]
