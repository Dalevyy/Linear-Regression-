#include <cstdlib>
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <string>
#include <iomanip>

using namespace std;

#define MAXLENGTH 1000
#define MINLENGTH 3

// ***************************************************************
//  Prototypes for external functions.
//	The "C" specifies to use the C/C++ style calling convention.

extern "C" int readQuatNum(int *);
extern "C" int lstEstMedian(int[], int);
extern "C" void insertionSort(int[], int);
extern "C" void lstStats(int[], int, int *, int *, int *, int *, int *);
extern "C" int lstMedian(int[], int);
extern "C" int lstAverage(int[], int);
extern "C" int lstKurtosis(int[], int, int);

// ***************************************************************
//  Error message routines

extern "C" void prtPrompt()
{
	cout << "Enter Value (quaternary): ";
	fflush(stdout);
	return;
}

extern "C" void errInvalidNum()
{
	cout << "Error, invalid number. ";
	cout << "Please re-enter." << endl;
	fflush(stdout);
	return;
}

extern "C" void errTooHigh()
{
	cout << "Error, number above maximum value. ";
	cout << "Please re-enter." << endl;
	fflush(stdout);
	return;
}

extern "C" void errTooLong()
{
	cout << "Error, user input exceeded " <<
		"length, input ignored. ";
	cout << "Please re-enter." << endl;
	fflush(stdout);
	return;
}

// ***************************************************************
//  Sinmple C++ program to call functions.
//	Notes, does not use any objects.

int main()
{

// --------------------------------------------------------------------
//  Declare variables and simple display header
	string	bars;
	bars.append(50,'-');

	int	i=0, newNumber=0;
	int	list[MAXLENGTH] = {};
	int	len = 0;
	int	min=0, max=0, med=0;
	int	estMed=0;
	int	sum=0, ave=0;
	int	kStat=0;

	cout << bars << endl;
	cout << "CS 218 - Assignment #9" << endl << endl;

// --------------------------------------------------------------------
//  Loops to read numbers from user.

	while (readQuatNum(&newNumber)) {
		list[len] = newNumber;
		len++;
	}

// --------------------------------------------------------------------
//  Ensure some numbers were read and, if so, display results.

	if (len < MINLENGTH) {
		cout << "Error, not enough numbers entered." << endl;
		cout << "Program terminated." << endl;
	} else {
		cout << bars << endl;
		cout << endl << "Program Results" << endl << endl;

		estMed = lstEstMedian(list, len);

		insertionSort(list, len);

		lstStats(list, len, &sum, &ave, &min, &max, &med);

		kStat = lstKurtosis(list, len, ave);

		cout << "Sorted List: " << endl;
		for ( i = 0; i < len; i++) {
			cout << list[i] << "  ";
			if ( (i%10)==9 || i==(len-1) ) cout << endl;
		}

		cout << endl;
		cout << "    Est Median =  " << setw(12) << estMed << endl;
		cout << "       Minimum =  " << setw(12) << min << endl;
		cout << "        Median =  " << setw(12) << med << endl;
		cout << "       Maximum =  " << setw(12) << max << endl;
		cout << "           Sum =  " << setw(12) << sum << endl;
		cout << "       Average =  " << setw(12) << ave << endl;
		cout << endl;
		cout << "    Median and Estimated Median Percent " << endl
		     << "    Difference =        " << setprecision(3) << fixed <<
			(((static_cast<double>(abs(estMed-med))) /
				(static_cast<double>(estMed+med)) / 2.0) * 100.0)
			<< endl;
		cout << endl;
		cout << "Kurtosis Value = " << kStat << endl;
		cout << endl;
	}

// --------------------------------------------------------------------
//  All done...

	return 0;

}

