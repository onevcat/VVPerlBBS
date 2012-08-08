my $b__dir = (-d '/home/onevcatc/perl'?'/home/onevcatc/perl':( getpwuid($>) )[7].'/perl');
unshift @INC,'lib/',$b__dir.'5/lib/perl5/',$b__dir.'5/lib/perl5/x86_64-linux-thread-multi/',map { $b__dir . $_ } @INC;
