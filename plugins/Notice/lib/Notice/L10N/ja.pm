package Notice::L10N::ja;

use strict;
use base qw/ Notice::L10N MT::L10N MT::Plugin::L10N /;
use vars qw( %Lexicon );

our %Lexicon = (
    '_PLUGIN_DESCRIPTION' => 'ユーザーダッシュボードへの通知機能を提供します。',

    'Message' => 'メッセージ',
    'Messages' => 'メッセージ',
    'message' => 'メッセージ',
    'messages' => 'メッセージ',
    
    'Check message [_1] by [_2]' => '[_2] よりメッセージがあります: [_1]',
    'Unread message [_1]' => '未読のメッセージが[_1]件あります。',
    
    # notice_config.tmpl
    'Default status' => 'デフォルトの<br />ステータス',
    'Default title' => 'デフォルトの<br />タイトル',
    'Default text' => 'デフォルトの<br />本文',
    
    # edit_notice.tmpl
    'Edit massage' => 'メッセージの編集',
    'Save changes to this message (s)' => 'メッセージを保存 (s)',
    'Delete this message (x)' => 'このメッセージを削除 (x)',
    'This message have been saved.' => 'メッセージを保存しました。',
    'This message can not show.' => 'このメッセージは表示できません',
    'Because of under writing, this message is not showed.' => 'このメッセージは編集中などの理由により表示されていません。',
    
    # list_notice.tmpl
	'The message has been deleted from the database.' => 'メッセージをデータベースから削除しました。',
	'The message has been changed status to draft.' => '選択したメッセージを下書きに戻しました。',
	'The message has been changed status to published.' => '選択したメッセージを公開しました。',
	'Read status' => '未読/<br />既読',
	
	# notice_table.tmpl
	'Modified On' => '更新日',
	'Published selected messages (a)' => '選択したメッセージを公開する (a)',
	'Draft selected messages (u)' => '選択したメッセージを下書きにする (u)',
	'Delete selected messages (x)' => '選択したメッセージを削除する (x)',
	
	# list_messages.tmpl
	'Unread messages' => '未読のメッセージ',
	'No unread messages.' => '未読のメッセージはありません。',
	'List all messages.' => 'すべてのメッセージ',
	
    );

1;
