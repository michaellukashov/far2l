mydir=WorkDir()
profile=mydir + "/profile"
left=mydir + "/left"
right=mydir + "/right"

StartApp(["--tty", "--nodetect", "--mortal", "-u", profile, "-cd", left, "-cd", right]);
ExpectString("Help - FAR2L");
TypeEscape();
ExpectString("OSC52");
TypeEscape();
Sleep(300);

TypeDown();
TypeFKey(4);
ExpectString("это можно копировать");
Sleep(500);

// Copy the whole line (it contains an embedded NUL and 0x02 before the tail)
TypeHome();
ToggleShift(true);
TypeEnd();
ToggleShift(false);
Sleep(200);
ToggleLCtrl(true);
TypeText("C");
ToggleLCtrl(false);
Sleep(300);

// Paste it at the start of the next line
TypeDown();
TypeHome();
ToggleLCtrl(true);
TypeText("V");
ToggleLCtrl(false);
Sleep(500);

TypeFKey(2);
Sleep(300);
TypeFKey(10);
Sleep(300);

CheckFilesDataSame(left + "/problem.txt", right + "/zz-expected.txt");

TypeFKey(10);
ExpectString("Do you want to quit FAR?");
TypeEnter();
ExpectAppExit(0);
0;
