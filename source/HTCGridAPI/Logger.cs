using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Reflection;

namespace HTCGrid
{

    public static class Logger
    {
        private static readonly object Sync = new object();
        private static Level _defaultLevel = Level.Info;
        private static bool _isTurned = true;
        private static bool _isTurnedDebug = false;

        public enum Level
        {
            None,
            Debug,
            Fine,
            Info,
            Warning,
            Error,
            Severe
        }

        static Logger()
        {
            lock (Sync)
            {

            }
        }

        public static void Info(string message)
        {

            Log(Level.Info, message);
        }
        public static void Debug(string message)
        {

            Log(Level.Debug, message);
        }
        public static void Error(string message)
        {

            Log(Level.Error, message);
        }

        public static void Log(Level level, string message)
        {
            var stackFrame = FindStackFrame();
            var methodBase = GetCallingMethodBase(stackFrame);
            var callingMethod = methodBase.Name;
            var callingClass = methodBase.ReflectedType.Name;
            var lineNumber = stackFrame.GetFileLineNumber();

            Log(level, message, callingClass, callingMethod, lineNumber);
        }

        public static void Log<TClass>(string message) where TClass : class
        {
            Log<TClass>(_defaultLevel, message);
        }

        public static void Log<TClass>(Level level, string message) where TClass : class
        {
            var stackFrame = FindStackFrame();
            var methodBase = GetCallingMethodBase(stackFrame);
            var callingMethod = methodBase.Name;
            var callingClass = typeof(TClass).Name;
            var lineNumber = stackFrame.GetFileLineNumber();

            Log(level, message, callingClass, callingMethod, lineNumber);
        }

        private static void Log(Level level, string message, string callingClass, string callingMethod, int lineNumber)
        {
            if (!_isTurned || (!_isTurnedDebug && level == Level.Debug))
                return;

            var currentDateTime = DateTime.Now;

            Console.WriteLine(string.Format("{0:dd.MM.yyyy HH:mm:ss}: {1} [line: {2} {3} -> {4}()]: {5}",
                            currentDateTime, level, lineNumber, callingClass,
                            callingMethod, message));
        }

        private static MethodBase GetCallingMethodBase(StackFrame stackFrame)
        {
            return stackFrame == null
                ? MethodBase.GetCurrentMethod() : stackFrame.GetMethod();
        }

        private static StackFrame FindStackFrame()
        {
            var stackTrace = new StackTrace();
            for (var i = 0; i < stackTrace.GetFrames().Count(); i++)
            {
                var methodBase = stackTrace.GetFrame(i).GetMethod();
                var name = MethodBase.GetCurrentMethod().Name;
                if (!methodBase.Name.Equals("Log") && !methodBase.Name.Equals("Info") && !methodBase.Name.Equals("Error") && !methodBase.Name.Equals("Debug") && !methodBase.Name.Equals(name))
                    return new StackFrame(i, true);
            }
            return null;
        }

        public static void On()
        {
            _isTurned = true;
        }

        public static void Off()
        {
            _isTurned = false;
        }

        public static void DebugOn()
        {
            _isTurnedDebug = true;
        }

        public static void DebugOff()
        {
            _isTurnedDebug = false;
        }
        public static bool isDebug()
        {
            return _isTurnedDebug;
        }
    }
}