=head1 Pulma::Service::Data::Operations

Part of Pulma system

Module providing service functions for the layer of data operations

Copyright (C) 2012 Fedor A. Fetisov <faf@ossg.ru>. All Rights Reserved

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License

=cut

package Pulma::Service::Data::Operations;

use strict;
use warnings;

use Encode qw(_utf8_off _utf8_on);

use Pulma::Service::Functions;

require Exporter;

our @ISA = ('Exporter');
our @EXPORT = qw( &check_filter_operation &compare_attributes
		  &normalize_structure &set_unicode_flag );

# Function: check_filter_operation
# Description
#	Validate an operation used in data filter
# Argument(s)
#	1. (string) operation
# Returns
#	true if operation is valid or false on error

sub check_filter_operation {
    my $operation = shift;

    return ( ($operation eq '=') ||
	     ($operation eq '<') ||
	     ($operation eq '>') ||
	     ($operation eq '<=') ||
	     ($operation eq '>=') ||
	     ($operation eq '<>') ||
	     ($operation eq '~' ) ||
	     ($operation eq '~~' ) );
}

# Function: compare_attributes
# Description
#	Compare given attributes of two entities in order to sort them
# Argument(s)
#	1. (link to hash) first entity
#	2. (link to hash) second entity
#	3. (string) attribute name
#	4. (string) sort mode (optional, default: ascendant sort with symbolic
#		    comparsion)
# Returns
#	1 if first entity should stand before second entity, 0 if they are equal,
#	or -1 if second entity should stand before first entity

sub compare_attributes {
    my $first = shift;
    my $second = shift;
    my $name = shift;
    my $order = shift;

# (in case of multiple values compare only first ones)
    my @attrsa;
    my @attrsb;

# initialize entities' attributes to sort by if they're not defined
    if ( !defined($first->{'attributes'}->{$name}) ) {
	$first->{'attributes'}->{$name} = [];
    }
    if ( !defined($second->{'attributes'}->{$name}) ) {
	$second->{'attributes'}->{$name} = [];
    }

# ascendant sort with symbolic comparsion
    if ($order eq 'asc') {

	@attrsa = sort { $a cmp $b } (@{$first->{'attributes'}->{$name}});
	@attrsb = sort { $a cmp $b } (@{$second->{'attributes'}->{$name}});

	return ($attrsa[0] || '') cmp ($attrsb[0] || '');

    }
# descendant sort with symbolic comparsion
    elsif ($order eq 'desc') {

	@attrsa = sort { $b cmp $a } (@{$first->{'attributes'}->{$name}});
	@attrsb = sort { $b cmp $a } (@{$second->{'attributes'}->{$name}});

	return ($attrsb[0] || '') cmp ($attrsa[0] || '');

    }
# ascendant sort with numeric comparsion
    elsif ($order eq 'nasc') {
	@attrsa = sort { $a <=> $b } (@{$first->{'attributes'}->{$name}});
	@attrsb = sort { $a <=> $b } (@{$second->{'attributes'}->{$name}});

	return (0 + ($attrsa[0] || 0)) <=> (0 + ($attrsb[0] || 0));

    }
# descendant sort with numeric comparsion
    elsif ($order eq 'ndesc') {

	@attrsa = sort { $b <=> $a } (@{$first->{'attributes'}->{$name}});
	@attrsb = sort { $b <=> $a } (@{$second->{'attributes'}->{$name}});

	return (0 + ($attrsb[0] || 0)) <=> (0 + ($attrsa[0] || 0));

    }
    return 0;
}

# Function: normalize_structure
# Description
#	Make numeric attributes of the structure actually numeric (change their
#	types from string to integer / float
# Argument(s)
#	1. (link to hash) structure
# Returns
#	Normalized structure
# IMPORTANT! One should aboid to call this function on structure containing
# cyclic links - this will cause recursion

sub normalize_structure {
    my $structure = shift;

    if (ref($structure) eq 'ARRAY') {
	foreach (@$structure) {
	    $_ = normalize_structure($_);
	}
    }
    elsif (ref($structure) eq 'HASH') {
	foreach (keys(%$structure)) {
	    $structure->{$_} = normalize_structure($structure->{$_});
	}
    }
    elsif (ref($structure) eq '') {
	if (check_decimal($structure, 1)) {

	    $structure += 0;

	}
    }

    return $structure;

}

# Function: set_unicode_flag
# Description
#	Set or unset unicode flag on all values in the given data structure
# Argument(s)
#	1. (various) structure to proceed with
#	2. (boolean) unicode flag value
# Returns
#	Resulting structure
# IMPORTANT! One should aboid to call this function on structure containing
# cyclic links - this will cause recursion

sub set_unicode_flag {
    my $structure = shift;
    my $flag = shift || 0;

    if (ref($structure) eq 'ARRAY') {
	foreach (@$structure) {
	    $_ = set_unicode_flag($_, $flag);
	}
    }
    elsif (ref($structure) eq 'HASH') {
	foreach (keys(%$structure)) {
	    $structure->{$_} = set_unicode_flag($structure->{$_}, $flag);
	}
    }
    elsif (ref($structure) eq '') {
	$flag ? _utf8_on($structure) : _utf8_off($structure);
    }

    return $structure;
}

1;
