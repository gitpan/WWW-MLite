package WWW::MLite::AuthSsn; # $Id: AuthSsn.pm 29 2014-08-01 06:53:56Z minus $
use strict;

=head1 NAME

WWW::MLite::AuthSsn - AAA mechanism support via sessions

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use WWW::MLite::AuthSsn;
    
    my $ssn = new WWW::MLite::AuthSsn(
        -dsn    => "driver:sqlite",
        -sid    => ($q->param("SID") || $q->cookie("SID") || undef),
        -key    => "SID",
        -expire => "+3M",
        -args   => { DataSource => '/my/folder/sessions.sqlt' },
    );
    
    # Authentication && Authorization
    $ssn->authn or die("Bad authentication");
    $ssn->authz or die("Bad authorization");
    
    ...
    
    # Access/Accounting
    $ssn->access or die("Access denied");


=head1 DESCRIPTION

Authorisation/Authentication/Access (AAA) mechanism support via sessions

=head2 METHODS

=over 8

=item B<new>

    my $ssn = new WWW::MLite::AuthSsn(
        -dsn    => $dsn, # See CGI::Session
        -sid    => $sid || undef), # Session IDentifier
        -key    => "SID", # Key name
        -expire => "+3M", # Expires
        -args   => { ... args ... }, # See CGI::Session
    );

Creating AuthSsn object

=item B<init>

    $ssn->init;

Initialising the session. For internal use only. Please do not use it

Method returns status operation: 1 - successfully; 0 - not successfully

=item B<update>

    $ssn->update;

Updating static data of the session. For internal use only. Please do not use it

=item B<authen>

    $ssn->authen;
    $ssn->authen( $callback, ...arguments... );

AAA Authentication.

The method returns status operation: 1 - successfully; 0 - not successfully

=item B<authz>

    $ssn->authz;
    $ssn->authz( $callback, ...arguments... );

AAA Authorization.

The method returns status operation: 1 - successfully; 0 - not successfully

=item B<access>

    $ssn->access;
    $ssn->access( $callback, ...arguments... );

AAA Accounting (AAA Access).

The method returns status operation: 1 - successfully; 0 - not successfully

=item B<get>

    $ssn->get( $key );

Returns user session value by $key

=item B<set>

    $ssn->set( $key, $value );

Sets user session value by $key

=item B<delete>

    $ssn->delete;

Delete the session

=item B<sid, usid>

    $ssn->sid;

Returns current usid value

=item B<expires>

    $ssn->expires;

Returns current expires value

=item B<status>

    $ssn->status;
    $ssn->status( $newstatus );

Returns status of a previously executed operation. If you specify $newstatus, there will push installation $newstatus

=item B<reason, reason_translate>

    $ssn->reason;
    $ssn->reason( $newreason );
    $ssn->reason_translate;

Returns reason of a previously executed operation. If you specify $newreason, there will push installation $newreason

Now supported following values: DEFAULT, OK, UNAUTHORIZED, ERROR, SERVER_ERROR, NEW, TIMEOUT, LOGIN_INCORRECT, 
PASSWORD_INCORRECT, DECLINED, AUTH_REQUIRED, FORBIDDEN.

For translating this values to regular form please use method reason_translate like that

=item B<error>

    $ssn->error();
    $ssn->error( $newerror );

Returns error of a previously executed operation. If you specify $newerror, there will push installation $newerror

=item B<toexpire>

    $ssn->toexpire( $time );

Returns expiration interval relative to ctime() form.

If used with no arguments, returns the expiration interval if it was ever set. 
If no expiration was ever set, returns undef. 

All the time values should be given in the form of seconds. 
Following keywords are also supported for your convenience:

    +-----------+---------------+
    |   alias   |   meaning     |
    +-----------+---------------+
    |     s     |   Second      |
    |     m     |   Minute      |
    |     h     |   Hour        |
    |     d     |   Day         |
    |     w     |   Week        |
    |     M     |   Month       |
    |     y     |   Year        |
    +-----------+---------------+

Examples:

    $ssn->toexpire("2h"); # expires in two hours
    $ssn->toexpire(3600); # expires in one hour

Note: all the expiration times are relative to session's last access time, not to its creation time. 
To expire a session immediately, call delete() method.

=item B<get_atime, get_ctime>

    $ssn->get_atime;
    $ssn->get_ctime;

Returns current atime and ctime values. Value atime - access time; ctime - create time

=item B<get_data>

    $ssn->get_data;

Returns user data of current session as hash-ref

=item B<get_expires>

    $ssn->get_expires;

Returns expiring interval of current session 

=back

=head1 CONFIGURATION

Sample in file conf/auth.conf:

    <Auth>
        expires +3m
        #sidkey usid
    </Auth>

=head1 EXAMPLES

=over 8

=item B<SQLite>

    my $dbh = DBI->connect("dbi:SQLite:dbname=/tmp/sessions.db", "","", { RaiseError => 1, sqlite_unicode => 1, });
    $dbh->do('CREATE TABLE IF NOT EXISTS sessions ( id CHAR(32) NOT NULL PRIMARY KEY, a_session TEXT NOT NULL )');
    my $ssn = new WWW::MLite::AuthSsn(
        -dsn    => "driver:sqlite",
        -sid    => ($q->param("SID") || $q->cookie("SID") || undef),
        -key    => "SID",
        -expire => "+3M",
        -args   => { Handle => $dbh },
    );

See L<CGI::Session::Driver::sqlite>

=back

=head1 HISTORY

See C<CHANGES> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<WWW::MLite>, L<CGI::Session>

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw($VERSION);
$VERSION = '1.00';

use CGI::Session;
use CTK::Util qw/ :API :FORMAT :DATE /;
use CTK::TFVals qw/ :ALL /;

use constant {
        SIDKEY          => 'usid',
        EXPIRES         => '+1h', # 3600sec as default
        
        # ���������� ������� �������� ���������
        STAT => {
            DEFAULT             => to_utf8('������ �����������'),
            NEW                 => to_utf8('������ ������� �������'), # new/authen
            OK                  => to_utf8('�������� ������ �������'), # new/authen/authez/access
            ERROR               => to_utf8('������ �� ���������� ��� �������� ������ �������� ������'), # new
            SERVER_ERROR        => to_utf8('������ �������'),
            TIMEOUT             => to_utf8('������ ����� ������ �����'), # new/access
            UNAUTHORIZED        => to_utf8('�� ����������������'), # authz/access/delete
            AUTH_REQUIRED       => to_utf8('��������� �����������'), # new
            FORBIDDEN           => to_utf8('������ ��������'), # authz/access
            DECLINED            => to_utf8('������� ������ �����������'), # authen
            LOGIN_INCORRECT     => to_utf8('������������ �����'), # authen
            PASSWORD_INCORRECT  => to_utf8('������������ ������'), # authen
        },
    };


sub new { # �����������: ������� ��� ���������� ����� ��������� �������
    my $class   = shift;
    my @in = read_attributes(
            [
                [qw/ DSN DRIVE DRIVER /],       # 0 - DSN (See CGI::Session)
                [qw/ SID USID /],               # 1 - USID User Session IDentifier
                [qw/ DSNARGS DSN_ARGS ARGS /],  # 2 - DSN_ARGS (See CGI::Session)
                [qw/ EXPIRE EXPIRES TIME /],    # 3 - Expires (���������� ������ ������� ����� ������������ ������)
                [qw/ KEY SIDKEY USIDKEY NAME /],# 4 - Name of session key (See CGI::Session)
            ],
        ,@_);
    
    # Defines & Checks
    my $dsn     = fv2null($in[0]);
    my $sid     = fv2undef($in[1]);
    my $args    = fv2undef($in[2]);
    my $expires = $in[3] || EXPIRES;
    my $sidkey  = $in[4] || SIDKEY;
    croak("Can't define DSN") unless $dsn;
    
    my $status = 0;
    my $reason = "ERROR";
    my $error  = _translate($reason);
    
    CGI::Session->name($sidkey);
    my $session = CGI::Session->load($dsn, $sid, $args);
    if ($sid) {
        # ��� ������� SID ������ ������� �����-������ ������!
        if ($session) {
            #my $session = new CGI::Session($dsn, undef, $args);
            if ( $session->is_expired ) {
                $reason = "TIMEOUT";
                $error  = "Session timed out (expired)";
                $sid    = undef;
            } else {
                if ( $session->is_empty ) {
                    #carp(">>>>>!!!! SESSION EMPTY !!!<<<");
                    $reason = "TIMEOUT";
                    $error  = "Session timed out (empty)";
                    $sid    = undef;
                } else {
                    $status = 1;
                    $reason = "OK";
                    $error = '';
                    $sid = $session->id() || undef;
                }
            }
        } else {
            $error  = CGI::Session->errstr();
            carp(sprintf(__PACKAGE__." LOAD ERROR>", $error));
            $sid    = undef;
        }
    } else {
        # �� ������ ������, ���� �� ������� USID. ��� ����������� ������ ������ ��������
        $error = "";
        unless ($session) {
            $error = CGI::Session->errstr();
            carp(sprintf(__PACKAGE__." LOAD ERROR>", $error));
        }
        return bless {
            status      => 0,
            reason      => "AUTH_REQUIRED",
            error       => $error,
            session     => $session,
            expire      => $expires, # ������������ ��������
            expires     => $class->toexpire($expires), # ��������������� (�������������) ��������
            $sidkey     => undef,
            sidkey      => $sidkey,
            predata     => {},
        }, $class;

    }
    my $self = bless {
        status      => $status,
        reason      => $reason,
        error       => $error,
        session     => $session,
        expire      => $expires, # ������������ ��������
        expires     => $class->toexpire($expires), # ������ � ������� ���������� ������� � ���!
        $sidkey     => $sid, # ��������� USID (����������� ���� ������ ��������� ��� ����������)
        sidkey      => $sidkey,
        predata     => {},
    }, $class;

    
    #
    # !!! ������������ ����� expire � ������� CGI::Session; ��� ����� ���������� ��� ��� ����, ��� �
    # !!! ��� ����� ������, ��� �������� ����. ������������� ������ �������� ����� ������ ��� ������
    #
    #$self->init if $status && $reason eq "NEW";
    return $self;
}
sub init { # ������������� �������������� ������ � ������
    my $self = shift;
    my $session = $self->{session};
    $session->param("ctime", time()); # ����� ��������
    $session->param("atime", time()); # ����� �������
    $session->param("expires", $self->{expires}); # ����� ����������������� ��� ������ ������
    $session->param("data", $self->{predata});    
    return 1;
}
sub update { # ���������� �������������� ������ � ������
    my $self = shift;
    my $session = $self->{session};
    
    $session->param("atime", time()); # ����� �������
    return 1;
}
sub authen { # AAA-authen
    #
    # ��������������. �������� - ��������� �� ������� ����� � ������
    #
    # ����� ��������� ��������:
    #   LOGIN_INCORRECT / PASSWORD_INCORRECT / DECLINED / OK
    #
    
    my $self = shift;
    my $callback = shift;

    # !!! callback here !!!
    if ($callback && ref($callback) eq 'CODE') {
        return 0 unless $callback->($self,@_);
    }
    
    $self->status(1);
    $self->reason("OK");
    $self->error('');
    
    return 1;
}
sub authz {  # AAA-authz
    #
    # �����������. �������� ����� � ���-������ ������ ��
    #
    # ����� ��������� ��������:
    #   UNAUTHORIZED / FORBIDDEN / OK
    #
    
    my $self = shift;
    my $callback = shift;
    my $_session = $self->{session};

    # !!! callback here !!!
    if ($callback && ref($callback) eq 'CODE') {
        return 0 unless $callback->($self,@_);
    }    
    
    # ����������� ������ �������. ����� ��������� ������
    #return 0 unless $self->init(undef,1);
    my $session;
    if ($self->sid) {
        $session = $_session;
    } else {
        $session = $_session->new();
        $self->init if $session;
    }
    if ($session) {
        $session->expire($self->{expire});
        $self->status(1);
        $self->reason("NEW");
        $self->error('');
        $self->{$self->{sidkey}} = $session->id() || undef;
        return 1;
    }
    
    my $error  = $session->errstr();
    carp(sprintf(__PACKAGE__." NEW ERROR>", $error));
    $self->status(0);
    $self->reason("UNAUTHORIZED");
    $self->error($error);
    $self->{sid} = undef;
    
    return 0;
    
}
sub access { # AAA-access
    #
    # �������� ������ ������ �� ������� ���������� ������� � ������������ �����������
    # ���-����� � ������
    #

    my $self = shift;
    my $callback = shift;
    
    # �������� - � ���� �� ������ ��� ������������� ??
    return 0 unless $self->status;

    # �������� expires � ���������� ������ ���������� �������.
    my $expires     = $self->get_expires;
    my $lastaccess  = $self->get_atime;
    my $newaccess   = time();
    #carp(">> expires: $expires; lastaccess: $lastaccess; newaccess: $newaccess");
    my $accessto = (($newaccess - $lastaccess) > $expires); # true - timeout
    if ($accessto) {
        $self->delete(); # ������� ���� ����� �������
        $self->status(0);
        $self->reason("TIMEOUT");
        $self->error(_translate("TIMEOUT"));
        return 0;
    }
    
    # !!! callback here !!!
    if ($callback && ref($callback) eq 'CODE') {
        return 0 unless $callback->($self,@_);
    }
    
    # ��� �������� ������ �������. ������ ��������!
    $self->update; # ��������� ����� �������
    $self->status(1);
    $self->reason("OK");
    $self->error('');
    return 1;
}

sub sid { # ��������� USID
    my $self = shift;
    return $self->{$self->{sidkey}} || undef;
}
sub usid { goto &sid }
sub get_expires { # ��������� expires �� ������
    my $self = shift;
    my $session = $self->{session};
    if (defined $session) {
        return $session->param("expires") || $self->{expires} || 0;
    }
    return $self->{expires} || 0;
}
sub get_ctime { # ��������� ctime �� ������
    my $self = shift;
    my $session = $self->{session};
    return 0 unless defined $session;
    return $session->param("ctime") || 0;
}
sub get_atime { # ��������� atime �� ������
    my $self = shift;
    my $session = $self->{session};
    return 0 unless defined $session;
    return $session->param("atime") || 0;
}
sub get_data { # ��������� data �� ������ ��� ��� (��������� ��� ������)
    my $self = shift;
    my $session = $self->{session};
    return undef unless defined $session;
    return $session->param("data") || {};
}
sub status { # ���������/��������� �������
    my $self = shift;
    my $ns   = shift;
    $self->{status} = fv2zero($ns) if defined $ns;
    return $self->{status};
}
sub reason { # ���������/��������� �������
    my $self = shift;
    my $nr   = shift;
    $self->{reason} = fv2null($nr) if defined $nr;
    return $self->{reason};
}
sub error { # ���������/��������� ������
    my $self = shift;
    my $ne   = shift;
    $self->{error} = fv2null($ne) if defined $ne;
    return $self->{error};
}
sub get { # ��������� ���������� ����� �� ���������������� ������ ������
    my $self = shift;
    my $key = shift || return;
    my $session = $self->{session};
    my $data = $self->get_data;
    my $value;
    if ($data && (ref($data) eq 'HASH') && !$session->is_empty) {
        $value = $data->{$key};
    } else { # ���� �� ��������� ��������
        $value = $self->{predata}->{$key};
    }
    return defined($value) ? $value : undef;
}
sub set { # ������ ���������� ����� � ���������������� ������ ������
    my $self = shift;
    my $key = shift || return 0;
    my $value = shift;
    my $session = $self->{session};
    my $data = $self->get_data;
    if ($data && (ref($data) eq 'HASH') && !$session->is_empty) {
        $data->{$key} = $value;
        $session->param("data", $data);
        return 1;
    } else { # ��������� �� ��������� ��������
        $data = $self->{predata};
        $data->{$key} = $value;
        return 1;
    }
    return 0;
}
sub delete { # �������� ������
    my $self = shift;
    my $session = $self->{session};
    if ($self->status && $session && $session->id) {
        $session->delete;
    }
    $self->{session} = undef ;
    $self->status(0);
    $self->reason("UNAUTHORIZED");
    $self->error(_translate("UNAUTHORIZED"));
    return 1;
}
sub reason_translate { # ������� �������� reason �� ������� ���� � � ������������
    my $self = shift;
    my $reason = shift || $self->reason();
    return _translate($reason);
}
sub toexpire { # ������� � expires
    my $self = shift;
    my $str = shift || 0;

    return 0 unless defined $str;
    return $1 if $str =~ m/^[-+]?(\d+)$/;

    my %_map = (
        s       => 1,
        m       => 60,
        h       => 3600,
        d       => 86400,
        w       => 604800,
        M       => 2592000,
        y       => 31536000
    );

    my ($koef, $d) = $str =~ m/^([+-]?\d+)([smhdwMy])$/;
    unless ( defined($koef) && defined($d) ) {
        croak "toexpire(): couldn't parse '$str' into \$koef and \$d parts. Possible invalid syntax";
    }
    return $koef * $_map{ $d };
}
sub _translate { # ������� �������� reason �� ������� ���� � � ������������
    my $reason = shift || 'DEFAULT';
    my $transtable = STAT;

    return $transtable->{DEFAULT} unless
        grep {$_ eq 'DEFAULT'} keys %$transtable;
        
    return $transtable->{$reason};
}
sub DESTROY {
    my $self = shift;
    my $session = $self->{session};
    $session->flush() if $session;
    undef $self;
}

1;

__END__