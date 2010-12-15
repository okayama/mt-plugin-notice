package MT::Plugin::Notice;
use strict;
use MT;
use MT::Plugin;
use base qw( MT::Plugin );

use Notice::Message;
use MT::Util qw( format_ts );

our $VERSION = '1.0';
our $SCHEMA_VERSION = '0.115';
our $PLUGIN_NAME = 'Notice';

###################################### Init Plugin #####################################

my $plugin = MT::Plugin::Notice->new( {
    id => $PLUGIN_NAME,
    key => 'message',
    description => '<MT_TRANS phrase=\'_PLUGIN_DESCRIPTION\'>',
    name => $PLUGIN_NAME,
    author_name => 'okayama',
    author_link => 'http://weeeblog.net/',
    version => $VERSION,
    schema_version => $SCHEMA_VERSION,
    l10n_class => $PLUGIN_NAME . '::L10N',
    settings => new MT::PluginSettings( [
        [ 'default_status', { Default => 1 } ],
        [ 'default_title', { Default => '' } ],
        [ 'default_text', { Default => '' } ],
    ] ),
    system_config_template => 'notice_config.tmpl',
} );

MT->add_plugin( $plugin );

sub init_registry {
    my $plugin = shift;
    $plugin->registry( {
        object_types => {
            'message' => $PLUGIN_NAME . '::Message',
        },
        widgets => {
            message => {
                label    => 'Message',
                template => 'widget/list_message.tmpl',
                handler  => \&_widget_message,
                set      => 'main',
                singular => 1,
                view     => 'user',
            },
        },
        applications => {
            cms => {
                menus => {
                    'message' => {
                        label => 'Message',
                        order => 900,
                    },
                    'message:list_message' => {
                        label => 'Manage',
                        order => 100,
                        mode => 'list_message',
#                        permission => 'administer',
                        view => 'system',
                    },
                    'message:create_message' => {
                        label => 'New',
                        mode => 'view',
                        args => { _type => 'message' },
                        order => 200,
                        permission => 'administer',
                        view => 'system',
                    },
                },
                methods => {
                    list_message => 'MT::Plugin::' . $PLUGIN_NAME . '::_list_message',
                    publish_messages => 'MT::Plugin::' . $PLUGIN_NAME . '::_posts_action',
                    draft_messages => 'MT::Plugin::' . $PLUGIN_NAME . '::_posts_action',
                },
            },
        },
        callbacks => {
            'MT::App::CMS::pre_run'
                => \&_cb_pre_run,
            'MT::App::CMS::template_source.header'
                => \&_cb_ts_header,
            'MT::App::CMS::template_param.edit_message'
                => \&_cb_tp_edit_message,
            'MT::App::CMS::template_param.list_message'
                => \&_cb_tp_list_message,
            'cms_post_save.message'
                => \&_cb_post_save_message,
        },
        tags => {
            modifier => {
                url_link => \&_url_link,
            },
        },
   } );
}

sub _url_link {
    my ( $text, $arg, $ctx ) = @_;
    $text =~ s/s?(https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+)/<a href="$1">$1<\/a>/;
    return $text;
}


sub _widget_message {
    my $app = shift;
    my ( $tmpl, $param ) = @_;

    my $user = $app->user;
    
    my @messages_loop;
    $param->{ test } = 'user1';
    my @messeges = MT->model( 'message' )->load( { status => Notice::Message::RELEASE(), viewed_authors => { not_like => '%,' . $app->user->id  . ',%' } } );
 
    for my $message ( @messeges ) {
        my $created_on_formatted = format_ts( undef, $message->created_on, undef, MT->current_language );
        my $modified_on_formatted = format_ts( undef, $message->modified_on, undef, MT->current_language );
        push @messages_loop, 
          {
            title => $message->title,
            id => $message->id,
            message => $message->text,
            created_on_formatted => $created_on_formatted,
            modified_on_formatted => $modified_on_formatted,
          };
    }
    $param->{ messages } = \@messages_loop;
}

sub _cb_post_save_message {
    my ( $cb, $app, $obj, $original ) = @_;
#    $obj->viewed_authors( undef );
    if ( $original ) {
        if ( $original->status == Notice::Message::RELEASE() && $obj->status == Notice::Message::HOLD() ) {
            $obj->viewed_authors( undef );
        }
    }
    $obj->save or $obj->errstr;
}

sub _cb_pre_run {
    my ( $eh, $app ) = @_;
    if ( ( $app->mode eq 'view' ) && ( $app->param( '_type' ) eq 'message' ) ) {
        $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl' );
        if ( my $message = MT->model( 'message' )->load( { id => $app->param( 'id' ) } ) ) {
# FIXME: How to display error ?
#             if ( $message->status == 1 && ! $app->user->is_superuser ) {
#                 $app->error( 'die' );
#             }
            my @viewed_author_ids = $message->viewed_author_ids;
            my $user_id = $app->user->id;
            unless ( grep { $_ eq $user_id } @viewed_author_ids ) {
                push( @viewed_author_ids, $user_id );
                my $viewed_authors = ',' . join( ',', @viewed_author_ids ) . ',';
                $viewed_authors =~ s/,,/,/g;
                $message->viewed_authors( $viewed_authors );
                $message->save or $message->errstr;
            }
#             $message->read_author_id( $user_id );
#             $message->save or $message->errstr;
        }
    }
}

sub _cb_tp_edit_message {
    my ( $cb, $app, $param ) = @_;
    if ( my $message_id = $app->param( 'id' ) ) {
        my $message = MT->model( 'message' )->load( { id => $message_id } );
        if ( ! $app->user->is_superuser && $message->status eq Notice::Message::HOLD() ) {
            $app->error( 'die' );
        }
    }
    $param->{ author_id } = $app->user->id;
    $param->{ can_edit_message } = $app->user->is_superuser;
    unless ( $app->param( 'id' ) ) {
        $param->{ default_status } = $plugin->get_config_value( 'default_status' );
        $param->{ default_title } = $plugin->get_config_value( 'default_title' );
        $param->{ default_text } = $plugin->get_config_value( 'default_text' );
    }
}

sub _cb_tp_list_message {
    my ( $cb, $app, $param ) = @_;
    $param->{ can_edit_message } = $app->user->is_superuser;
}

sub _cb_ts_header {
    my ( $cb, $app, $tmpl ) = @_;
    return unless $app->mode eq 'dashboard';
    my $released_messeges_count = MT->model( 'message' )->count( { status => Notice::Message::RELEASE() } ) || 0;
# FIXME: how can I load with CF.
#    my $read_messeges_count = MT->model( 'message' )->count( { status => Notice::Message::RELEASE(), read_author_id => $app->user->id } ) || 0;
    my $read_messeges_count = MT->model( 'message' )->count( { status => Notice::Message::RELEASE(), viewed_authors => { like => '%,' . $app->user->id  . ',%' } } ) || 0;
    my $unread_messeges_count = $released_messeges_count - $read_messeges_count;
    return if _can_edit_message( $app );
    return unless $unread_messeges_count;
    my $insert = <<MTML;
    <mtapp:statusmsg
        id="notice"
        class="success">
            <__trans_section component="Notice">
            <a href="<mt:var name="sctipt_url">?__mode=list_message"><__trans phrase="Unread message [_1]" params="$unread_messeges_count"></a>
            </__trans_section>
    </mtapp:statusmsg>
MTML
    $$tmpl =~ s/(<mt:if\sname="system_msg">.*?<\/mt:if>)/$1$insert/s;

#     my @messages = MT->model( 'message' )->load( { status => 2 }, { 'sort' => 'created_on', direction => 'ascend' } );
#     for my $message ( @messages ) {
#         my @viewed_author_ids = $message->viewed_author_ids;
#         my $user_id = $app->user->id;
#         next if grep { $_ eq $user_id } @viewed_author_ids;
#         my $title = '<a href="<mt:var name="sctipt_url">?__mode=view&amp;_type=message&amp;id=' . $message->id . '">' . $message->title . '</a>';
#         my $author_name = $message->author_name;
#         my $insert = <<MTML;
#         <mtapp:statusmsg
#             id="notice"
#             class="success">
#                 <__trans_section component="Notice">
#                 <__trans phrase="Unread message [_1]" params="$unread_messeges_count">
#                 <__trans phrase="Check message [_1] by [_2]" params="$title%%$author_name">
#                 </__trans_section>
#         </mtapp:statusmsg>
# MTML
#         $$tmpl =~ s/(<mt:if\sname="system_msg">.*?<\/mt:if>)/$1$insert/s;
#     }
}

sub _posts_action {
    my $app = shift;
    my $perms = $app->permissions;
    my $user  = $app->user;
    my $admin = $user->is_superuser;
    my @ids = $app->param( 'id' ) or return $app->errtrans( 'Invalid request.' );
    my $status;
    if ( $app->mode eq 'draft_messages' ) {
        $status = 1;
    } elsif ( $app->mode eq 'publish_messages' ) {
        $status = 2;
    }
    my $saved;
    for my $id ( @ids ) {
        next unless $id;
        next unless ( $id =~ /^[0-9]{1,}$/ );
        my $message = Notice::Message->load( $id );
        if ( defined $message ) {
            if ( $message->status != $status ) {
                $message->status( $status );
                $message->save or die $message->errstr;
                unless ( $saved ) {
                    $app->add_return_arg( status_changed => $status );
                    $saved = 1;
                }
            }
        }
    }
    $app->call_return;

}

sub _can_edit_message {
    my ( $app ) = @_;
    return $app->user->is_superuser;
}

sub _list_message {
    my $app = shift;
    my $author = $app->user;
    my $author_id = $author->id;
    my ( %messages );
    my $perms = $app->permissions;
    my $state_editable = _can_edit_message( $app );
    my $message_pkg = $app->model( 'message' );
    my $code = sub {
        my ( $obj, $row ) = @_;
        my $blog = $obj->blog;
        unless ( $blog ) {
            $blog = MT->model( 'blog' )->load( undef, { 'sort' => 'id', direction => 'ascend' } );
        }
        if ( my $status = $obj->status ) {
            if ( $status == 2 ) {
                $row->{ visible } = 1;
            }
        }
        if ( my $created_ts = $obj->created_on ) {
            $row->{ created_on_formatted } =
                format_ts( undef, $created_ts, ( $blog || undef ), $app->user ? $app->user->preferred_language : undef );
        }
        if ( my $modified_ts = $obj->modified_on ) {
            $row->{ modified_on_formatted } =
                format_ts( undef, $modified_ts, ( $blog || undef ), $app->user ? $app->user->preferred_language : undef );
        }
        if ( my $viewed_authors = $obj->viewed_authors ) {
            $row->{ 'read' } = ( $viewed_authors =~ /,$author_id,/ );
        }
        $row->{ has_edit_access } = $state_editable;
    };
    my %terms;
    my %param;
    if ( $app->param( 'saved_deleted' ) ) {
        $param{ saved_deleted } = 1;
    }
    unless ( $app->user->is_superuser ) {
        $terms{ status } = 2;
    }
    $param{ status_changed } = $app->param( 'status_changed' );
    $param{ object_type } = 'message';
    $param{ screen_id } = 'list-message';
    $param{ screen_class } = 'list-message';
    $param{ 'LIST_NONCRON' } = 1;
    $param{ search_label } = $plugin->translate( 'Message' );
    $param{ state_editable } = $state_editable;
    $app->{ 'plugin_template_path' } = File::Spec->catdir( $plugin->path, 'tmpl' );
    
    return $app->listing(
        {
            type => 'message',
            code => $code,
            args => { sort => 'created_on', direction => 'descend' },
            params => \%param,
            terms => \%terms,
        }
    );
}




1;