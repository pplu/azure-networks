package Azure::Networks {
  use Moose;
  use XML::Simple;

  our $VERSION = '0.01';

  has file => (
    is => 'ro', 
    isa => 'Str|Undef'
  );

  has netinfo => (
    is => 'ro',
    isa => 'HashRef',
    default => sub {
      my $self = shift;
      #die "Can't get some properties from derived results" if (not $self->url);
      #my $response = HTTP::Tiny->new->get($self->url);
      #die "Error downloading URL" unless ($response->{ success });

      my $ref = XMLin($self->file);
      return {
        prefixes =>
          [ map { 
              my $region = $_->{ Name };
              map {
                { region => $region,
                  service => 'AZURE',
                  ip_prefix => $_->{ Subnet }
                }
              } @{ $_->{ IpRange } }
            } @{ $ref->{ Region } } 
          ]
      }
    },
    lazy => 1,
  );

  has networks => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub {
      return shift->netinfo->{ prefixes };
    },
    lazy => 1,
  );

  has regions => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub {
      my ($self) = @_;
      my $regions = {};
      map { $regions->{ $_->{ region } } = 1 } @{ $self->networks };
      return [ keys %$regions ];
    },
    lazy => 1,
  );

  sub by_region {
    my ($self, $region) = @_;
    return AWS::Networks->new(
      url => undef,
      sync_token => $self->sync_token,
      networks => [ grep { $_->{ region } eq $region } @{ $self->networks }  ]
    );
  }

  has services => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub {
      my ($self) = @_;
      my $services = {};
      map { $services->{ $_->{ service } } = 1 } @{ $self->networks };
      return [ keys %$services ];
    },
    lazy => 1,
  );

  has cidrs => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub {
      my ($self) = @_;
      return [ map { $_->{ ip_prefix } } @{ $self->networks } ];
    },
    lazy => 1,
  );
}

1;
