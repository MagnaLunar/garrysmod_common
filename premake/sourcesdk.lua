newoption({
	trigger = "sourcesdk",
	description = "Sets the path to the SourceSDK directory",
	value = "path to SourceSDK directory"
})

local function GetSDKPath(folder)
	folder = folder or _OPTIONS["sourcesdk"] or os.getenv("SOURCE_SDK") or DEFAULT_SOURCESDK_FOLDER

	if folder == nil then
		error("you didn't supply a path to your SourceSDK copy")
	end

	folder = CleanPath(folder)
	local dir = path.getabsolute(folder)
	if not os.isdir(dir) then
		error(dir .. " doesn't exist (SourceSDK)")
	end

	return folder
end

local function AddCommon(folder)
	folder = GetSDKPath(folder)

	local curfilter = GetFilter()
	local nosystem = curfilter.system == nil

	filter({})

	defines(_PROJECT_SERVERSIDE and "GAME_DLL" or "CLIENT_DLL")
	includedirs({
		folder .. "/common",
		folder .. "/public"
	})

	if _PROJECT_SERVERSIDE then
		includedirs({
			folder .. "/game/server",
			folder .. "/game/shared"
		})
	else
		includedirs({
			folder .. "/game/client",
			folder .. "/game/shared"
		})
	end

	if nosystem or HasFilter(FILTER_WINDOWS) then
		filter(MergeFilters({"system:windows", curfilter.configurations}, curfilter.extra))
			defines("WIN32")
			libdirs(folder .. "/lib/public")

			if curfilter.configurations == nil or HasFilter(FILTER_DEBUG) then
				filter(MergeFilters({"system:windows", "configurations:Debug"}, curfilter.extra))
					linkoptions("/NODEFAULTLIB:\"libcmt\"")
			end
	end

	if nosystem or HasFilter(FILTER_LINUX) then
		filter(MergeFilters({"system:linux", curfilter.configurations}, curfilter.extra))
			defines({"COMPILER_GCC", "POSIX", "_POSIX", "LINUX", "_LINUX", "GNUC", "NO_MALLOC_OVERRIDE"})
			--libdirs(folder .. "/lib/public/linux32")
			linkoptions("-L" .. path.getabsolute(folder) .. "/lib/public/linux32")
	end

	if nosystem or HasFilter(FILTER_MACOSX) then
		filter(MergeFilters({"system:macosx", curfilter.configurations}, curfilter.extra))
			defines({"COMPILER_GCC", "POSIX", "_POSIX", "OSX", "GNUC", "NO_MALLOC_OVERRIDE"})
			libdirs(folder .. "/lib/public/osx32")
	end

	filter(curfilter.patterns)

	_SOURCE_SDK_INCLUDED = true
end

function IncludeSDKTier0(folder)
	folder = GetSDKPath(folder)

	AddCommon(folder)

	local curfilter = GetFilter()
	local nosystem = curfilter.system == nil

	filter({})

	includedirs(folder .. "/public/tier0")

	if nosystem or HasFilter(FILTER_WINDOWS) then
		filter(MergeFilters({"system:windows", curfilter.configurations}, curfilter.extra))
			links("tier0")
	end

	if nosystem or HasFilter(FILTER_LINUX) then
		filter(MergeFilters({"system:linux", curfilter.configurations}, curfilter.extra))
			prelinkcommands("cp -f " .. path.getabsolute(folder) .. "/lib/public/linux32/libtier0.so " .. path.getabsolute(folder) .. "/lib/public/linux32/libtier0_srv.so")
			links(_PROJECT_SERVERSIDE and "tier0_srv" or "tier0")
	end

	if nosystem or HasFilter(FILTER_MACOSX) then
		filter(MergeFilters({"system:macosx", curfilter.configurations}, curfilter.extra))
			links("tier0")
	end

	filter(curfilter.patterns)
end

function IncludeSDKTier1(folder)
	folder = GetSDKPath(folder)

	AddCommon(folder)

	local name = project().name
	local curfilter = GetFilter()
	local nosystem = curfilter.system == nil

	filter({})

	includedirs(folder .. "/public/tier1")
	links("tier1")

	if nosystem or HasFilter(FILTER_WINDOWS) then
		filter(MergeFilters({"system:windows", curfilter.configurations}, curfilter.extra))
			links({"vstdlib", "ws2_32", "rpcrt4"})
	end

	if nosystem or HasFilter(FILTER_LINUX) then
		filter(MergeFilters({"system:linux", curfilter.configurations}, curfilter.extra))
			prelinkcommands("cp -f " .. path.getabsolute(folder) .. "/lib/public/linux32/libvstdlib.so " .. path.getabsolute(folder) .. "/lib/public/linux32/libvstdlib_srv.so")
			links(_PROJECT_SERVERSIDE and "vstdlib_srv" or "vstdlib")
	end

	if nosystem or HasFilter(FILTER_MACOSX) then
		filter(MergeFilters({"system:macosx", curfilter.configurations}, curfilter.extra))
			links("vstdlib")
	end

	project("tier1")
		kind("StaticLib")
		warnings("Default")
		defines("TIER1_STATIC_LIB")
		includedirs({
			folder .. "/public/tier0",
			folder .. "/public/tier1"
		})
		vpaths({["Source files"] = folder .. "/tier1/**.cpp"})
		AddCommon(folder)
		files({
			folder .. "/tier1/bitbuf.cpp",
			folder .. "/tier1/byteswap.cpp",
			folder .. "/tier1/characterset.cpp",
			folder .. "/tier1/checksum_crc.cpp",
			folder .. "/tier1/checksum_md5.cpp",
			folder .. "/tier1/checksum_sha1.cpp",
			folder .. "/tier1/commandbuffer.cpp",
			folder .. "/tier1/convar.cpp",
			folder .. "/tier1/datamanager.cpp",
			folder .. "/tier1/diff.cpp",
			folder .. "/tier1/generichash.cpp",
			folder .. "/tier1/ilocalize.cpp",
			folder .. "/tier1/interface.cpp",
			folder .. "/tier1/KeyValues.cpp",
			folder .. "/tier1/kvpacker.cpp",
			folder .. "/tier1/lzmaDecoder.cpp",
			folder .. "/tier1/mempool.cpp",
			folder .. "/tier1/memstack.cpp",
			folder .. "/tier1/NetAdr.cpp",
			folder .. "/tier1/rangecheckedvar.cpp",
			folder .. "/tier1/reliabletimer.cpp",
			folder .. "/tier1/snappy-sinksource.cpp",
			folder .. "/tier1/snappy-stubs-internal.cpp",
			folder .. "/tier1/snappy.cpp",
			folder .. "/tier1/sparsematrix.cpp",
			folder .. "/tier1/splitstring.cpp",
			folder .. "/tier1/stringpool.cpp",
			folder .. "/tier1/strtools.cpp",
			folder .. "/tier1/tier1.cpp",
			folder .. "/tier1/tokenreader.cpp",
			folder .. "/tier1/uniqueid.cpp",
			folder .. "/tier1/utlbinaryblock.cpp",
			folder .. "/tier1/utlbuffer.cpp",
			folder .. "/tier1/utlbufferutil.cpp",
			folder .. "/tier1/utlstring.cpp",
			folder .. "/tier1/utlsymbol.cpp"
		})

		filter("system:windows")
			defines("_DLL_EXT=dll")
			files(folder .. "/tier1/processor_detect.cpp")

		filter("system:linux")
			defines("_DLL_EXT=so")
			files({
				folder .. "/tier1/processor_detect_linux.cpp",
				folder .. "/tier1/qsort_s.cpp",
				--folder .. "/tier1/pathmatch.cpp"
			})

		filter("system:macosx")
			defines("_DLL_EXT=dylib")
			files({
				folder .. "/tier1/processor_detect_linux.cpp",
				folder .. "/tier1/qsort_s.cpp",
				--folder .. "/tier1/pathmatch.cpp"
			})

		filter("action:gmake")
			buildoptions("-std=gnu++11")

	project(name)

	filter(curfilter.patterns)
end

function IncludeSDKTier2(folder)
	folder = GetSDKPath(folder)

	AddCommon(folder)

	local curfilter = GetFilter()

	filter({})

	includedirs(folder .. "/public/tier2")
	links("tier2")

	filter(curfilter.patterns)
end

function IncludeSDKTier3(folder)
	folder = GetSDKPath(folder)

	AddCommon(folder)

	local curfilter = GetFilter()

	filter({})

	includedirs(folder .. "/public/tier3")
	links("tier3")

	filter(curfilter.patterns)
end

function IncludeSourceSDK(folder)
	folder = GetSDKPath(folder)
	IncludeSDKTier0(folder)
	IncludeSDKTier1(folder)
end

function IncludeSteamAPI(folder)
	folder = GetSDKPath(folder)

	AddCommon(folder)

	local curfilter = GetFilter()

	filter({})

	includedirs(folder .. "/public/steam")
	links("steam_api")

	filter(curfilter.patterns)
end
