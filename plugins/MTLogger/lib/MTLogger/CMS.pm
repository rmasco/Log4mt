package MTLogger::CMS;
use strict;

use utf8;
use Fcntl;
use MT::Util qw( format_ts epoch2ts ts2epoch relative_date offset_time encode_url dirify encode_url );
use MT::Log;


sub output {
    my ($eh, $obj, $original) = @_;
    my $app = MT->instance;

    require File::Spec;
    my $dir = MT->config('LoggerFilePath') or return;

    my @time = localtime(time);
    my $file = sprintf(
        "mtlog-%04d%02d%02d.log",
        $time[5] + 1900,
        $time[4] + 1,
        $time[3]
    );
    my $logger_file = File::Spec->catfile( $dir, $file );


    my $created_on = _get_date_time();
    my $log = '['.$created_on.']';
    $log .= ' ['._log_level_label($obj->level).']';
    $log .= ' '.$obj->ip;
    $log .= ' '.($obj->message);

    sysopen( my $fh, $logger_file, O_WRONLY | O_APPEND | O_CREAT ) or die "$!:$file";
    print $fh $log."\n";
    close $fh;


}

sub _get_date_time {
    my $format = shift;
    $format = "%04d\/%02d\/%02d %02d:%02d:%02d";
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    $year += 1900;
    $mon++;
    return sprintf($format,$year,$mon,$mday,$hour,$min,$sec);
}

sub _log_level_label {
    my $level = shift;
    my $level_label = "";

    if($level == MT::Log::INFO()){
        $level_label = 'INFO';
    } elsif ($level == MT::Log::WARNING()){
        $level_label = 'WARNING';
    } elsif ($level == MT::Log::ERROR()){
        $level_label = 'ERROR';
    } elsif($level == MT::Log::SECURITY()){
        $level_label = 'SECURITY';
    } elsif($level == MT::Log::DEBUG()){
        $level_label = 'DEBUG';
    } 

    return $level_label;
}

sub loggerfilepath {
    my $cfg = shift;
    my ( $path, $default );
    return $cfg->set_internal( 'LoggerFilePath', @_ ) if @_;

    unless ( $path = $cfg->get_internal('LoggerFilePath') ) {
        $path = $default
            = File::Spec->catdir( MT->instance->support_directory_path,
            'logs' );
    }
    if ( !( -d $path and -w $path ) ) {
        my @dirs
            = ( $path, ( $default && $path ne $default ? ($default) : () ) );
        require File::Spec;
        foreach my $dir (@dirs) {
            my $msg = '';
            if ( -d $dir and -w $dir ) {
                $path = $dir;
            } else {
                require File::Path;
                eval { File::Path::mkpath( [$dir], 0, 0777 ); $path = $dir; };
                if ($@) {
                    $msg = MT->translate(
                        'Error creating logs directory, [_1]. [_2]',
                        $dir, $@
                    );
                }
            }

            if ($msg) {

                # Issue MT log within an eval block in the
                # event that the plugin error is happening before
                # the database has been initialized...
                require MT::Log;
                MT->log(
                    {   message  => $msg,
                        class    => 'system',
                        level    => MT::Log::ERROR(),
                        category => 'performance-log',
                    }
                );
            }
            last if $path;
        }
    }
    return $path;
}

1;
