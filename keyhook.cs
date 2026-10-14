// keyhook.exe - global keystroke counting helper (WH_KEYBOARD_LL low-level hook)
// On every physical key release (WM_KEYUP/WM_SYSKEYUP, auto-repeat counts once) it
// sends a 1-byte UDP signal to 127.0.0.1:<port>; no key content is captured or reported.
// Exits automatically once its parent process (the HUD) is gone.
// Usage: keyhook.exe <udp port> <parent PID>
// Build: csc /nologo /target:winexe /out:keyhook.exe keyhook.cs
using System;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Threading;

static class KeyHook
{
	delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);

	const int WH_KEYBOARD_LL = 13;
	const int WM_KEYUP = 0x0101;
	const int WM_SYSKEYUP = 0x0105;
	const int SYNCHRONIZE = 0x00100000;
	const int INFINITE = -1;

	[DllImport("user32.dll", SetLastError = true)]
	static extern IntPtr SetWindowsHookEx(int idHook, HookProc lpfn, IntPtr hMod, uint dwThreadId);

	[DllImport("user32.dll")]
	static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

	[DllImport("user32.dll")]
	static extern int GetMessage(out MSG lpMsg, IntPtr hWnd, uint wMin, uint wMax);

	[DllImport("kernel32.dll")]
	static extern IntPtr GetModuleHandle(string name);

	[DllImport("kernel32.dll", SetLastError = true)]
	static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

	[DllImport("kernel32.dll", SetLastError = true)]
	static extern uint WaitForSingleObject(IntPtr hHandle, int dwMilliseconds);

	[StructLayout(LayoutKind.Sequential)]
	struct MSG
	{
		public IntPtr hwnd;
		public uint message;
		public IntPtr wParam;
		public IntPtr lParam;
		public uint time;
		public int ptX;
		public int ptY;
	}

	static Socket _sock;
	static int _port;
	static HookProc _proc;
	static IntPtr _hook;

	static IntPtr Callback(int nCode, IntPtr wParam, IntPtr lParam)
	{
		if (nCode >= 0)
		{
			int msg = wParam.ToInt32();
			if (msg == WM_KEYUP || msg == WM_SYSKEYUP)
			{
				try { _sock.SendTo(new byte[] { 1 }, new IPEndPoint(IPAddress.Loopback, _port)); } catch { }
			}
		}
		return CallNextHookEx(_hook, nCode, wParam, lParam);
	}

	static void WatchParent(int parentPid)
	{
		IntPtr h = OpenProcess(SYNCHRONIZE, false, parentPid);
		if (h != IntPtr.Zero)
			WaitForSingleObject(h, INFINITE);
		Environment.Exit(0);
	}

	static void Main(string[] args)
	{
		_port = args.Length > 0 ? int.Parse(args[0]) : 52777;
		_sock = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);

		Thread watcher = new Thread(delegate () { WatchParent(args.Length > 1 ? int.Parse(args[1]) : 0); });
		watcher.IsBackground = true;
		watcher.Start();

		_proc = Callback;
		_hook = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(null), 0);
		if (_hook == IntPtr.Zero)
			Environment.Exit(2);
		MSG m;
		while (GetMessage(out m, IntPtr.Zero, 0, 0) > 0) { }
	}
}
