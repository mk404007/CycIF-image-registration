#!/usr/bin/env python3

import tkinter
from tkinter import filedialog

tkinter.Tk().withdraw() # prevents an empty tkinter window from appearing

folder_path = filedialog.askdirectory()

print(folder_path)
