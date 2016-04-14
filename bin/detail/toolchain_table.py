# Copyright (c) 2014, Ruslan Baratov & Luca Martini
# Copyright (c) 2014, Michele Caini
# All rights reserved.

import os
import platform

class Toolchain:
  def __init__(
      self,
      name,
      generator,
      arch='',
      vs_version='',
      ios_version='',
      osx_version='',
      xp=False,
      nocodesign=False,
  ):
    self.name = name
    self.generator = generator
    self.arch = arch
    self.vs_version = vs_version
    self.ios_version = ios_version
    self.osx_version = osx_version
    self.is_nmake = (self.generator == 'NMake Makefiles')
    self.is_msvc = self.generator.startswith('Visual Studio')
    self.is_make = self.generator.endswith('Makefiles')
    self.is_ninja = (self.generator == 'Ninja')
    self.xp = xp
    self.is_xcode = (self.generator == 'Xcode')
    self.multiconfig = (self.is_xcode or self.is_msvc)
    self.nocodesign = nocodesign
    self.verify()

  def verify(self):
    if self.arch:
      assert(self.is_nmake or self.is_msvc or self.is_ninja)
      assert(self.arch == 'amd64' or self.arch == 'x86')

    if self.is_nmake or self.is_msvc:
      assert(self.vs_version)

    if self.ios_version or self.osx_version:
      assert(self.generator == 'Xcode')

    if self.xp:
      assert(self.vs_version)

toolchain_table = [
    Toolchain('default', ''),
    Toolchain('ot-iphoneos-arm64', 'Xcode', ios_version='9.3'),
    Toolchain('ot-iphoneos-armv7s', 'Xcode', ios_version='9.3'),
    Toolchain('ot-iphoneos-armv7', 'Xcode', ios_version='9.3'),
    Toolchain('ot-iphonesimulator-i386', 'Xcode', ios_version='9.3'),
    Toolchain('ot-iphonesimulator-x86_64', 'Xcode', ios_version='9.3'),
    Toolchain('ot-appletvsimulator-x86_64', 'Xcode', ios_version='9.2'),
    Toolchain('ot-appletvos-arm64', 'Xcode', ios_version='9.2'),
    Toolchain('ot-osx-x86_64', 'Xcode', osx_version='10.11'),
    Toolchain('ot-ubuntu-x86_64', 'Unix Makefiles'),
    Toolchain('ot-centos-x86_64', 'Unix Makefiles'),
    Toolchain('ot-android-armv7a', 'Unix Makefiles'),
    Toolchain('ot-android-arm64', 'Unix Makefiles'),
    Toolchain('ot-android-x86', 'Unix Makefiles'),
    Toolchain(
        'ot-windows-x86',
        'Visual Studio 12 2013',
        arch='x86',
        vs_version='12',
        xp=True
    ),
    Toolchain(
        'ot-windows-x86_64',
        'Visual Studio 12 2013 Win64',
        arch='amd64',
        vs_version='12'
    ),
]

def get_by_name(name):
  for x in toolchain_table:
    if name == x.name:
      return x
  sys.exit('Internal error: toolchain not found in toolchain table')
