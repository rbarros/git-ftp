#!/bin/sh

oneTimeSetUp() {
	cd "$TESTDIR/../"

	GIT_FTP_CMD="$(pwd)/git-ftp"
	: ${GIT_FTP_USER=ftp}
	: ${GIT_FTP_PASSWD=}
	: ${GIT_FTP_ROOT=localhost/}

	START=$(date +%s)
}

oneTimeTearDown() {
	END=$(date +%s)
	DIFF=$(( $END - $START ))
	echo "It took $DIFF seconds"
}

setUp() {
	GIT_PROJECT_PATH=$(mktemp -d -t git-ftp-XXXX)
	GIT_PROJECT_NAME=$(basename $GIT_PROJECT_PATH)

	GIT_FTP_URL="$GIT_FTP_ROOT$GIT_PROJECT_NAME"

	CURL_URL="ftp://$GIT_FTP_USER:$GIT_FTP_PASSWD@$GIT_FTP_URL"

	cd $GIT_PROJECT_PATH

	# make some content
	for i in 1 2 3 4 5
	do
		echo "$i" >> ./"test $i.txt"
		mkdir -p "dir $i"
		echo "$i" >> "dir $i/test $i.txt"
	done;

	# git them
	git init > /dev/null 2>&1
	git add . > /dev/null 2>&1
	git commit -a -m "init" > /dev/null 2>&1
}

tearDown() {
	rm -rf $GIT_PROJECT_PATH
	command -v lftp >/dev/null 2>&1 && {
		lftp -u $GIT_FTP_USER,$GIT_FTP_PASSWD $GIT_FTP_ROOT -e "set ftp:list-options -a; rm -rf '$GIT_PROJECT_NAME'; exit" > /dev/null 2>&1
	}
}

test_backup() {
	cd $GIT_PROJECT_PATH

	# make some changes
	echo "1" >> "./test 1.txt"
	git commit -a -m "change" > /dev/null 2>&1

	# this should pass
	push=$($GIT_FTP_CMD push -u $GIT_FTP_USER -p '$GIT_FTP_PASSWD' $GIT_FTP_URL -b)
	rtrn=$?
	assertEquals 0 $rtrn
}

# load and run shUnit2
TESTDIR=$(dirname $0)
. $TESTDIR/shunit2-2.1.6/src/shunit2
