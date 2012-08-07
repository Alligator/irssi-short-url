use strict;

use IO::Socket::INET;
use Irssi;
use Irssi::Irc;

sub getURL {
  my ($server, $msg, $nick, $addr, $target) = @_;
  my $isgd_api_request = "GET /create.php?format=simple&url=%s HTTP/1.1\r\nHost: is.gd\r\n\r\n";

  return unless $msg =~ /.*(https?:\/\/([^\/]+)[^\s]*)/;
  my @tokens = split(/ /, $msg);
  my $out;

  foreach (@tokens) {
    if ($_ =~ /.*(https?:\/\/([^\/]+)[^\s]*)/) {
      # we got a url
      my ($url, $domain) = ($1, $2);

      # leave short urls be
      if (length($url) < 30) {
        $out .= "$_ ";
        next;
      }

      my $sock = new IO::Socket::INET(
        PeerAddr => 'is.gd',
        PeerPort => 'http(80)',
        Proto    => 'tcp'
      ) or die "ERROR in Socket Creation : $!\n";

      my $request = sprintf($isgd_api_request, $url);
      my $data;

      $sock->send($request);
      $sock->recv($data, 1024);
      $sock->close();

      $data =~ /(http.*)\r\n/;

      $out .= "$1 ($domain) ";
    } else {
      $out .= "$_ ";
    }
  }
  Irssi::signal_continue($server, $out, $nick, $addr, $target);
}

Irssi::signal_add_first("message public", "getURL");
Irssi::signal_add_first("ctcp action", "getURL");
