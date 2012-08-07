use strict;

use IO::Socket::INET;
use Irssi;
use Irssi::Irc;

sub getURL {
  my ($server, $msg, $nick, $addr, $target) = @_;

  return 0 unless $msg =~ /.*(http:\/\/([^\/]+)[^\s]*)/;
  my $url = $1;
  my $domain = $2;

  if (length($url) < 30) {
    return;
  }

  my $isgd_api_request = "GET /create.php?format=simple&url=%s HTTP/1.1\r\nHost: is.gd\r\n\r\n";

  my $sock = new IO::Socket::INET(
    PeerAddr => 'is.gd',
    PeerPort => 'http(80)',
    Proto    => 'tcp'
  ) or die "ERROR in Socket Creation : $!\n";

  my $request = sprintf($isgd_api_request, $url);

  $sock->send($request);
  my $data;
  $sock->recv($data, 1024);

  $sock->close();

  $data =~ /(http.*)\r\n/;

  my $short = $1;
  $msg =~ s/http:\/\/[^\s]*/$short ($domain)/;

  #$server->print("$target", "$msg", MSGLEVEL_CLIENTCRAP);
  Irssi::signal_continue($server, $msg, $nick, $addr, $target);
}

Irssi::signal_add_first("message public", "getURL");
Irssi::signal_add_first("ctcp action", "getURL");
