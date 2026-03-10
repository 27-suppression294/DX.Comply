/// <summary>
/// DX.Comply.Tests.IDE.ReadmeSupport
/// Tests the README loading and lightweight Markdown-to-HTML conversion.
/// </summary>
///
/// <remarks>
/// These tests protect the IDE info tab against regressions in the repository
/// path discovery logic and the small markdown renderer used by the embedded
/// browser preview.
/// </remarks>
///
/// <copyright>
/// Copyright © 2026 Olaf Monien
/// Licensed under MIT
/// </copyright>

unit DX.Comply.Tests.IDE.ReadmeSupport;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TIDEReadmeSupportTests = class
  public
    [Test]
    procedure ConvertMarkdownToHtmlDocument_RendersCommonReadmeStructures;
    [Test]
    procedure LoadDXComplyReadmeMarkdown_LoadsRepositoryReadme;
  end;

implementation

uses
  System.SysUtils,
  DX.Comply.IDE.ReadmeSupport;

procedure TIDEReadmeSupportTests.ConvertMarkdownToHtmlDocument_RendersCommonReadmeStructures;
const
  cMarkdown =
    '# Title' + sLineBreak + sLineBreak +
    'Intro with [link](https://example.com) and `code`.' + sLineBreak + sLineBreak +
    '- Bullet one' + sLineBreak +
    '- Bullet two' + sLineBreak + sLineBreak +
    '1. First' + sLineBreak +
    '2. Second' + sLineBreak + sLineBreak +
    '| Name | Value |' + sLineBreak +
    '| ---- | ----- |' + sLineBreak +
    '| A | B |' + sLineBreak + sLineBreak +
    '```pascal' + sLineBreak +
    'ShowMessage(''Hi'');' + sLineBreak +
    '```';
var
  LHtml: string;
begin
  LHtml := ConvertMarkdownToHtmlDocument(cMarkdown, 'Sample');

  Assert.Contains(LHtml, '<h1>Title</h1>');
  Assert.Contains(LHtml, '<a href="https://example.com">link</a>');
  Assert.Contains(LHtml, '<code>code</code>');
  Assert.Contains(LHtml, '<ul>');
  Assert.Contains(LHtml, '<ol>');
  Assert.Contains(LHtml, '<table>');
  Assert.Contains(LHtml, '<pre><code>');
  Assert.Contains(LHtml, 'ShowMessage(''Hi'');');
end;

procedure TIDEReadmeSupportTests.LoadDXComplyReadmeMarkdown_LoadsRepositoryReadme;
var
  LMarkdown: string;
begin
  LMarkdown := LoadDXComplyReadmeMarkdown;

  Assert.Contains(LMarkdown, '# DX.Comply');
  Assert.Contains(LMarkdown, '## TL;DR');
end;

initialization
  TDUnitX.RegisterTestFixture(TIDEReadmeSupportTests);

end.