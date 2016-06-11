###################################################################
##
## Author : Tamas Horvath
## Date   : 2016.05.03.
##
###################################################################

use strict;
use warnings;

use Text::Unaccent::PurePerl qw(unac_string);

# Testing argument whether exists or not
(my $file_path = $ARGV[0]) or die "Please give file path as argument";

# Testing argument validness (is a real file or not)
(-f $file_path) or die "Please give a path to a real file!";

# Testing for file extension
($file_path =~ /^.*\.csv$/) or die "Please give a CSV file!";

print "Processing following file: $file_path \n\n";

# Number of outpu columns
my $valid_col_index = 11;

# Name of the account to be inserted
my $account_name = "Budapest Bank Folyoszamla";

# Name of the new file to be created during processing
my $new_filename = $file_path;
$new_filename =~ s/^(.*)\.csv$/$1_PROCESSED.csv/gi;

# State variables
# ## avoid garbage at the end of file
my $valid_data_found = 0;

# ## mark first valid row
my $first_valid_row = 1;

# Old column names in order vs new column names in order:
# 0_____1_____________2_________3____________4_______5______6______7______________________________________________________________________________
# Date, Account Name, Category, Description, Amount, Check, Payee, Note
# 0_________1___________2_________________3_______________4_______5_______6____________7____________8____________9_________10____________11_______
# Értéknap, Tranzakció, Könyvelés dátuma, Referenciaszám, Összeg, Deviza, Közlemény 1, Közlemény 2, Közlemény 3, Jogosult, Credit/Debit, Kategória

# Pairing Old and new columns
# 0_________1_____________2_________3____________4_______5_______6__________7_____________________________________________________________________
# Date, 	Account Name, Category, Description, Amount, Check,  Payee, 	Note
# 0______________________________________________4_______________9__________6____________7____________8___________________________________________
# Értéknap, BUDAPESTBANK, empty   , empty        Összeg, empty,  Jogosult,  Közlemény 1, Közlemény 2, Közlemény 3

# Opening file

open (my $target_fh, '>', $new_filename) or die "Cannot open file for write under path: $new_filename";
	open (my $init_fh, '<', $file_path) or die "Cannot open file for read under path: $file_path";
		while (<$init_fh>) {
			chomp;

			if ($_ !~ /^[0-9].*/) {
				if ($valid_data_found) {
					last;
				}
				next;
			}

			$valid_data_found = 1;

			my @old_columns = split(',', $_);
			chomp(@old_columns);

			# Initializing new data
			my @new_columns = (" ") x 8;

			# Translating date format
			$old_columns[0] =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)/$3\/$2\/$1/gi;
			$new_columns[0] = $old_columns[0];

			#Adding account names
			$new_columns[1] = $account_name;

			#Category
			$new_columns[2] = unac_string($old_columns[-1]);
			
			#Adding amount
			$new_columns[4] = $old_columns[4];

			#Adding Payee
			$new_columns[6] = unac_string($old_columns[9]);

			#Adding Note
			$new_columns[7] = unac_string($old_columns[6] . $old_columns[7] . $old_columns[8]);

			my $new_row = join(',', @new_columns);
			
			if ($first_valid_row) {
				print $target_fh "Date,Account Name,Category,Description,Amount,Check,Payee,Note\n";
				$first_valid_row = 0;
			}
			
			# Print to new file
			print $target_fh "$new_row\n";
		}
	close ($init_fh);
close ($target_fh);
