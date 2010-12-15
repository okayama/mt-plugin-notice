package Notice::Message;
use strict;

@Notice::Message::ISA = qw( MT::Object );
__PACKAGE__->install_properties( {
    column_defs => {
        'id' => 'integer not null auto_increment',
        'author_id' => 'integer',
        'blog_id' => 'integer',
        'entry_id' => 'integer',
        'status' => 'integer',
        'title' => 'string(255)',
        'text' => 'text',
        'viewed_authors' => 'string(255)',
        'read_author_id' => 'integer meta',
    },
    indexes => {
        'entry_id' => 1,
        'author_id' => 1,
        'blog_id' => 1,
        'status' => 1,
    },
    datasource => 'message',
    class_type => 'message',
    primary_key => 'id',
    meta => 1,
    audit => 1,
} );

sub HOLD () { 1 }
sub RELEASE () { 2 }

sub viewed_author_ids {
    my ( $message ) = @_;
    my $viewed_authors = $message->viewed_authors or '';
    return split( /,/, $viewed_authors );
}

sub author_name {
    my ( $message ) = @_;
    $message->cache_property( 'author_name', sub {
        my $author_id = $message->author_id or '';
        my $author = MT->model( 'author' )->load( { id => $author_id } ) or '';
        return $author->nickname || $author->name;
    } );
}

sub blog {
    my ( $message ) = @_;
    $message->cache_property( 'blog', sub {
        my $blog_id = $message->blog_id;
        MT->model( 'blog' )->load( $blog_id ) or '';
    } );
}

sub class_label {
    my $plugin = MT->component( 'Notice' );
    return $plugin->translate( 'Message' );
}

sub class_label_plural {
    my $plugin = MT->component( 'Notice' );
    return $plugin->translate( 'Message' );
}

1;