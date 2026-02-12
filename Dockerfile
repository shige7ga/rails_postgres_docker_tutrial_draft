FROM ruby:3.2

# 必要なパッケージをインストール
RUN apt-get update -qq && \
    apt-get install -y nodejs postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 作業ディレクトリを設定
WORKDIR /myapp

# bundleディレクトリを作成し、全ユーザーに書き込み権限を付与
RUN mkdir -p /bundle && chmod 777 /bundle

# gemのbinディレクトリをPATHに追加
ENV PATH="/bundle/bin:${PATH}"

# エントリーポイントスクリプトをコピー
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

# デフォルトコマンド
CMD ["rails", "server", "-b", "0.0.0.0"]
