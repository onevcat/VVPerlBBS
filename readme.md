## OneV's Denの掲示板の説明

OneV's Denの掲示板はパールで会員制の掲示板。これはカヤックの入社課題についてのリポジトリです。これから、詳しく説明しています。

### Demo

オンラインのDemoはここです：<http://perl.onevcat.com>

GitHubにリポジトリはここです：<https://github.com/onevcat/VVPerlBBS>

オンラインDemoの作業環境：

* Linux Kernel 2.6.18-408.el5.lve0.8.61.1
* Apache 2.2.22
* MySQL 5.5.24-cll
* Perl v5.8.8

ローカルのDemoもある、作業環境は：

* Mac OSX 10.7.4
* Apache 2.2.21
* MySQL 5.5.25a-log
* Perl v5.12.3

オンラインのDemoも、ローカルのDemoも使うことができる。

ブラウザーにテストを通過する：

* Chrome 21.0.1180.57
* Safari 5.1.7 (7534.57.2)
* Firefox 10.0.2
* Internet Explorer 9

---

### 機能

* 会員機能
	* 会員登録が行えることができる。<http://perl.onevcat.com/registrer.pl>。
	* 毎頁の中に、ログイン／ログアウトができる。
	* 毎頁の中に、自分のログイン状態か’guest‘状態かが表記がある。
	* ログインしていない状態でも掲示板の閲覧・書き込みはできる。
	* ログイン名はユーザー毎にユニークのものとし、既存のログイン名では会員登録ができないようにする。
* 掲示板機能
	* トピック、スレッド、返信ができる。掲示板の管理者はトピックを作成することができる。会員は毎トピックにスレッドと返信することができる。
	* 既存のスレッドに返信することができる。
	* スレッドを投稿する時は、タイトル、本文を入力必须する。
	* 返信を投稿する時は、本文を入力必须する。タイトルじゃないことがいいです。
	* スレッドと返信を投稿する時、画像で投稿ことができる、1Mまでの画像は5枚までできる。
	* 投稿の番号、ログイン名（ログインしていない場合はguest）、投稿日、時刻が自動で表示される。
	* トピックとスレッド一覧のページがある。新しく書き込みのあったトピックとスレッドを上位に表示する。
	* 24時間以内に投稿のあったスレッドには「NEW」マークをつける。
	* 一覧ではタイトルの他に最終更新日時を表示する。
	* ページャーがあるて、トピックとスレッドと返信の数が10枚以上になったら次のページのリンクがある。
	* 本文検索することができる。検索のボタンがホームページの中にある。
	* 投稿する際は入力＞確認＞投稿完了の3ステップを踏ませる。
	* 管理者用のページがある<http://perl.onevcat.com/admin-login.pl>。このページから、掲示板にログインしたら、管理者になる。管理者は任意なトピックとスレッドと返信を削除することができる。管理者のパスワードをメールで送りました。
	* 会員は自分の投稿を削除することができる。
	* 本文中にURLやメールアドレスがあった場合は自動でリンクを貼ることができる。例：<http://perl.onevcat.com/thread.pl?id=34>
	* 本文中でHTMLタグの使用はできない。ユーザーはHTMLタグを入力することができる。でも、このタグをプレーンテキストで表示する。
* その他
	* 文字とコードはUTF-8にする。世界中に全部な言語を表示することができる。

---

### 自分のオリジナルの機能

* 任意なページは会員IDがある。このリンクを押して、その会員の会員センターへ行くことができる。
* 自分の会員センターで、自分のパスワードを変更することができる。
* 自分の会員センターで、他の会員からもらうメッセージの一覧がある。
* 他の会員の会員センターで、その会員にメッセージを送ることができる。

投稿することだけ、会員の発表は誰も読むことができる。特定な会員に連絡したい方がない。特定な会員にメッセージを送りたいん時、会員センターに送信することがいいです。この機能のために、会員センターを
実装しだ。自分のパスワードを変更することは通常な機能だ。

---

### 必要なモジュールのリスト

* [CGI](http://search.cpan.org/~markstos/CGI.pm-3.59/lib/CGI.pm)
* [CGI::Session](http://search.cpan.org/~markstos/CGI-Session-4.48/lib/CGI/Session.pm) 
* [Data::FormValidator](http://search.cpan.org/~markstos/Data-FormValidator-4.70/lib/Data/FormValidator.pm)
* [DBD::mysql](http://search.cpan.org/~capttofu/DBD-mysql-4.021/lib/DBD/mysql.pm) 
* [DBI](http://search.cpan.org/~timb/DBI-1.622/DBI.pm)
* [Digest::MD5](http://search.cpan.org/~gaas/Digest-MD5-2.52/MD5.pm)
* [Email::Find](http://search.cpan.org/~miyagawa/Email-Find-0.10/lib/Email/Find.pm)
* [Encode](http://search.cpan.org/~dankogai/Encode-2.45/Encode.pm)
* [Fatal](http://search.cpan.org/~pjf/autodie-2.12/lib/Fatal.pm)
* [File::Basename](http://search.cpan.org/~rjbs/perl-5.16.0/lib/File/Basename.pm)
* [File::Copy](http://search.cpan.org/~rjbs/perl-5.16.0/lib/File/Copy.pm)
* [File::Spec](http://search.cpan.org/~smueller/PathTools-3.33/lib/File/Spec.pm)
* [File::Temp](http://search.cpan.org/~tjenness/File-Temp-0.22/Temp.pm)
* [HTML::Template](http://search.cpan.org/~wonko/HTML-Template-2.91/lib/HTML/Template.pm)
* [URI::Find](http://search.cpan.org/~mschwern/URI-Find-20111103/lib/URI/Find.pm)

このモジュール全部が[CPAN](http://search.cpan.org/)の中にある。

---

### インストールガイド

1. 「必要なモジュールのリスト」の中にのモジュールがインストルを確保する。
2. OSとサーバーの種類は大丈夫ですが、MySQLは必要です。データベースとユーザーを作ってください。
3. 「2.」のデータベースに、perlbbs.sql.zipの中にの内容をインポートしてください。
4. 全部なファイルを自分のサイトのrootディレクトリーにコーピしてください。
5. /config/config.plの中に、データベースの名前と、ユーザーの名前と、ユーザーのパスワードを入力してください。
6. /libpath.plの中に、必要なモジュールパスを入力してください。
7. ディレクトリーの訪問許可をセットください。
	* /lib、/html_template、/config　=> 750
	* /style、/img　=> 755
	* /img/user_content、/img/user_content_tmp　=> 777
8. これで、いいですよ。

---

### ありがとう

PerlとWebの初心者ですから、違うことが教えて頂けませんか。どうぞよろしくお願いします。

以上です、王巍から。

2012.08.08







　 