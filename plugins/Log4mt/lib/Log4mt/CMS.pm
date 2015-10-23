package Log4mt::CMS;
use strict;

use utf8;
use MT::Log;
use Log::Log4perl qw(:easy);
use Log::Log4perl::Level;

sub output {
    my ( $eh, $obj, $original ) = @_;
    my $app           = MT->instance;
    my $support_dir   = $app->support_directory_path();
    my $log_file_path = $support_dir . '/log4mt.log';
    my $log_format    = '%d [%p] %m%n';
    Log::Log4perl->easy_init(
        {   file   => '>>' . $log_file_path,
            layout => $log_format
        }
    );
    my $logger = get_logger();
    my $level  = _log_level_label( $obj->level );
    my $message;
    $message .= '['.$obj->class.']' if $obj->class;
    $message .= '['.$obj->category.']' if $obj->category;
    $message .= $obj->message;
    $logger->log( $level, $message );
}

sub _log_level_label {
    my $level = shift;

    if ( $level == MT::Log::INFO() ) {
        return $INFO;
    }
    elsif ( $level == MT::Log::WARNING() ) {
        return $WARN;
    }
    elsif ( $level == MT::Log::ERROR() ) {
        return $ERROR;
    }
    elsif ( $level == MT::Log::SECURITY() ) {
        return $INFO;
    }
    elsif ( $level == MT::Log::DEBUG() ) {
        return $DEBUG;
    }
}

1;
