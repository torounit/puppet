# Manage Unix groups.  This class is annoyingly complicated; There
# is some variety in whether systems use 'groupadd' or 'addgroup', but OS X
# significantly complicates the picture by using NetInfo.  Eventually we
# will also need to deal with systems that have their groups hosted elsewhere
# (e.g., in LDAP).  That will likely only be a problem for OS X, since it
# currently does not use the POSIX interfaces, since lookupd's cache screws
# things up.

require 'etc'
require 'facter'

module Puppet
    newtype(:group) do
        @doc = "Manage groups.  This type can only create groups.  Group
            membership must be managed on individual users.  This resource type
            uses the prescribed native tools for creating groups and generally
            uses POSIX APIs for retrieving information about them.  It does
            not directly modify ``/etc/group`` or anything.
            
            For most platforms, the tools used are ``groupadd`` and its ilk;
            for Mac OS X, NetInfo is used.  This is currently unconfigurable,
            but if you desperately need it to be so, please contact us."

        ensurable do
            desc "Create or remove the group."

            newvalue(:present) do
                provider.create

                :group_created
            end

            newvalue(:absent) do
                provider.delete

                :group_removed
            end
        end

        newproperty(:gid) do
            desc "The group ID.  Must be specified numerically.  If not
                specified, a number will be picked, which can result in ID
                differences across systems and thus is not recommended.  The
                GID is picked according to local system standards."

            def retrieve
                return provider.gid
            end

            def sync
                if self.should == :absent
                    raise Puppet::DevError, "GID cannot be deleted"
                else
                    provider.gid = self.should
                    :group_modified
                end
            end

            munge do |gid|
                case gid
                when String
                    if gid =~ /^[-0-9]+$/
                        gid = Integer(gid)
                    else
                        self.fail "Invalid GID %s" % gid
                    end
                when Symbol
                    unless gid == :absent
                        self.devfail "Invalid GID %s" % gid
                    end
                end

                return gid
            end
        end

        newparam(:name) do
            desc "The group name.  While naming limitations vary by
                system, it is advisable to keep the name to the degenerate
                limitations, which is a maximum of 8 characters beginning with
                a letter."

            isnamevar
        end

        newparam(:allowdupe, :boolean => true) do
            desc "Whether to allow duplicate GIDs.  This option does not work on
                FreeBSD (contract to the ``pw`` man page)."
                
            newvalues(:true, :false)

            defaultto false
        end
    end
end

