#pragma once
#include <memory>
#include <string>
#include <atomic>
#include <list>

#include "Host.h"
#include "FileInformation.h"

class HostLocal : public IHost
{
public:
	HostLocal();
	virtual ~HostLocal();

	virtual std::string SiteName() override;
	virtual void GetIdentity(Identity &identity) override;


	virtual std::shared_ptr<IHost> Clone() override;

	virtual void ReInitialize() override;
	virtual void Abort() override;

	virtual mode_t GetMode(const std::string &path, bool follow_symlink = true) override;
	virtual unsigned long long GetSize(const std::string &path, bool follow_symlink = true) override;
	virtual void GetInformation(FileInformation &file_info, const std::string &path, bool follow_symlink = true) override;

	virtual void FileDelete(const std::string &path) override;
	virtual void DirectoryDelete(const std::string &path) override;

	virtual void DirectoryCreate(const std::string &path, mode_t mode) override;
	virtual void Rename(const std::string &path_old, const std::string &path_new) override;

	virtual void SetTimes(const std::string &path, const timespec &access_timem, const timespec &modification_time) override;
	virtual void SetMode(const std::string &path, mode_t mode) override;

	virtual void SymlinkCreate(const std::string &link_path, const std::string &link_target) override;
	virtual void SymlinkQuery(const std::string &link_path, std::string &link_target) override;


	virtual std::shared_ptr<IDirectoryEnumer> DirectoryEnum(const std::string &path) override;
	virtual std::shared_ptr<IFileReader> FileGet(const std::string &path, unsigned long long resume_pos = 0) override;
	virtual std::shared_ptr<IFileWriter> FilePut(const std::string &path, mode_t mode, unsigned long long size_hint, unsigned long long resume_pos = 0) override;

	virtual bool Alive() override;
};
