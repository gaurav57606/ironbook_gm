  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final unsyncedCount = ref.watch(unsyncedCountProvider).value ?? 0;

    return StatusBarWrapper(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  if (unsyncedCount > 0) _buildSyncBanner(unsyncedCount),
                  _buildGymProfileCard(auth),
                  _buildAccountGroup(auth),
                  _buildGymSettingsGroup(auth),
                  _buildDataSyncGroup(),
                  _buildSupportGroup(),
                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
