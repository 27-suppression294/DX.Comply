/// <summary>
/// DX.Comply.Locale.EN
/// Forces English locale for Delphi RTL resource strings.
/// </summary>
///
/// <remarks>
/// Delphi loads localized resource strings (e.g. German "Dateiname ist leer"
/// instead of "Filename is empty") from satellite DLLs matching the system
/// locale. This unit calls SetLocaleOverride('en') during initialization,
/// which forces the RTL to skip locale-specific resource DLLs and use the
/// built-in English strings instead.
///
/// IMPORTANT: This unit must be listed FIRST in the uses clause of any
/// application that requires English-only RTL messages, so its initialization
/// section runs before other units load resource strings.
/// </remarks>
///
/// <copyright>
/// Copyright © 2026 Olaf Monien
/// Licensed under MIT
/// </copyright>

unit DX.Comply.Locale.EN;

interface

implementation

initialization
  SetLocaleOverride('en');

end.
