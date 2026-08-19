#pragma once

// Minimal ATL-compatible string converters for flutter_secure_storage_windows
// when Visual Studio ATL (atlstr.h) is not installed.
#include <windows.h>
#include <tchar.h>
#include <string>

class CA2W {
  std::wstring wstr_;

 public:
  LPWSTR m_psz = nullptr;

  explicit CA2W(const char* s) {
    if (!s || !*s) {
      wstr_.clear();
      m_psz = const_cast<LPWSTR>(L"");
      return;
    }
    int n = MultiByteToWideChar(CP_UTF8, 0, s, -1, nullptr, 0);
    if (n <= 0) {
      n = MultiByteToWideChar(CP_ACP, 0, s, -1, nullptr, 0);
    }
    if (n <= 0) {
      wstr_.clear();
      m_psz = const_cast<LPWSTR>(L"");
      return;
    }
    wstr_.assign(static_cast<size_t>(n - 1), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s, -1, wstr_.data(), n);
    m_psz = wstr_.data();
  }

  operator LPCWSTR() const { return m_psz ? m_psz : L""; }
};

class CW2A {
  std::string str_;

 public:
  LPSTR m_psz = nullptr;

  explicit CW2A(const wchar_t* s) {
    if (!s || !*s) {
      str_.clear();
      m_psz = const_cast<LPSTR>("");
      return;
    }
    int n = WideCharToMultiByte(CP_UTF8, 0, s, -1, nullptr, 0, nullptr, nullptr);
    if (n <= 0) {
      str_.clear();
      m_psz = const_cast<LPSTR>("");
      return;
    }
    str_.assign(static_cast<size_t>(n - 1), '\0');
    WideCharToMultiByte(CP_UTF8, 0, s, -1, str_.data(), n, nullptr, nullptr);
    m_psz = str_.data();
  }

  operator const char*() const { return m_psz ? m_psz : ""; }
  operator std::string() const { return str_; }
};
