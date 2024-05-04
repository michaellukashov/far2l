#ifndef COLORER_USTR_H
#define COLORER_USTR_H

#include <filesystem>
#include "colorer/strings/icu/common_icu.h"
#include "xercesc/util/XMLString.hpp"

class UStr
{
 public:
  [[nodiscard]] static UnicodeString to_unistr(int number);
  [[nodiscard]] static std::string to_stdstr(const UnicodeString* str);
  [[nodiscard]] static std::string to_stdstr(const uUnicodeString& str);
  [[nodiscard]] static std::string to_stdstr(const XMLCh* str);
  [[nodiscard]] static std::unique_ptr<XMLCh[]> to_xmlch(const UnicodeString* str);
  [[nodiscard]] static std::filesystem::path to_filepath(const uUnicodeString& str);
#ifdef _WINDOWS
  [[nodiscard]] static std::wstring to_stdwstr(const UnicodeString* str);
  [[nodiscard]] static std::wstring to_stdwstr(const UnicodeString& str);
  [[nodiscard]] static std::wstring to_stdwstr(const uUnicodeString& str);
#endif

  inline static bool isEmpty(const XMLCh* string) { return *string == '\0'; }

  static std::unique_ptr<CharacterClass> createCharClass(const UnicodeString& ccs, int pos,
                                                         int* retPos, bool ignore_case);

  static bool HexToUInt(const UnicodeString& str_hex, unsigned int* result);

  static int8_t caseCompare(const UnicodeString& str1, const UnicodeString& str2);
  static int32_t indexOfIgnoreCase(const UnicodeString& str1, const UnicodeString& str2, int32_t pos = 0);
};

#endif  // COLORER_USTR_H
